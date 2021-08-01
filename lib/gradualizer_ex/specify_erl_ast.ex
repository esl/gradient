defmodule GradualizerEx.SpecifyErlAst do
  @moduledoc """
  Module adds missing line information to the Erlang abstract code produced 
  from Elixir AST.

  FIXME use anno instead of lines 
  """

  import GradualizerEx.Utils

  @type token :: tuple()
  @type form :: tuple()
  @type options :: keyword()

  @doc """

  """
  @spec specify([form()]) :: [form()]
  def specify(forms) do
    with {:attribute, 1, :file, {path, 1}} <- hd(forms),
         path <- to_string(path),
         {:ok, code} <- File.read(path),
         {:ok, tokens} <- :elixir.string_to_tokens(String.to_charlist(code), 1, 1, path, []) do
      add_missing_loc_literals(tokens, forms)
    else
      error ->
        IO.puts("Error occured when specifying forms : #{error}")
        forms
    end
  end

  @doc """
  Function takes forms and traverse them to add missing location for literals. 
  Firstly the parent location is set, then it is matched 
  with tokens to precise the literal line.
  """
  @spec add_missing_loc_literals([token()], [form()]) :: [form()]
  def add_missing_loc_literals(tokens, abstract_code) do
    # For now works only for integers and atoms 
    # FIXME handle binary, charlist, float and others if needed

    opts = []
    Enum.map(abstract_code, fn x -> mapper(x, tokens, opts) |> elem(0) end)
  end

  @spec foldl([form()], [token()], options()) :: {[form()], [token()]}
  defp foldl(forms, tokens, opts) do
    List.foldl(forms, {[], tokens}, fn form, {acc_forms, acc_tokens} ->
      {res_form, res_tokens} = mapper(form, acc_tokens, opts)
      {[res_form | acc_forms], res_tokens}
    end)
    |> update_in([Access.elem(0)], &Enum.reverse/1)
  end

  @spec pass_tokens(form(), [token()]) :: {form(), [token()]}
  defp pass_tokens(form, tokens) do
    {form, tokens}
  end

  @spec mapper(form(), [token()], options()) :: {form(), [token()]}
  defp mapper(form, tokens, opts)

  defp mapper({:function, _line, :__info__, _args_numb, _children} = form, tokens, _opts) do
    pass_tokens(form, tokens)
  end

  defp mapper({:function, line, name, args_numb, children}, tokens, opts) do
    opts = Keyword.put(opts, :line, line)
    {children, tokens} = foldl(children, tokens, opts)

    {:function, line, name, args_numb, children}
    |> pass_tokens(tokens)
  end

  defp mapper({:fun, line, {:clauses, children}}, tokens, opts) do
    {children, tokens} = foldl(children, tokens, opts)

    {:fun, line, {:clauses, children}}
    |> pass_tokens(tokens)
  end

  defp mapper({:case, line, condition, children}, tokens, opts) do
    # NOTE In Elixir `if`, `case` and `cond` statements are represented 
    # as a `case` in abstract code.
    opts = Keyword.put(opts, :line, line)

    {new_condition, tokens} = mapper(condition, tokens, opts)

    #NOTE use map because generated clauses can be in wrong order
    new_children = Enum.map(children, fn x -> mapper(x, tokens, opts) |> elem(0) end)
    # {new_children, new_tokens} = foldl(children, tokens, opts)

    {:case, line, new_condition, new_children}
    |> pass_tokens(tokens)
  end

  defp mapper({:clause, loc, args, [], children}, tokens, opts) do
    # TODO Adapt the whole module to handle location
    # FIXME Handle generated clauses. Right now the literals inherit lines 
    # from the parents without checking them with tokens 
    line = get_line_from_loc(loc)
    opts = Keyword.put(opts, :line, line)

    {args, tokens} =
      if !was_generate?(loc) do
        foldl(args, tokens, opts)
      else
        {args, tokens}
      end

    {children, tokens} = children |> foldl(tokens, opts)

    {:clause, line, args, [], children}
    |> pass_tokens(tokens)
  end

  defp mapper({:match, line, left, right}, tokens, opts) do
    opts = Keyword.put(opts, :line, line)
    {right, tokens} = mapper(right, tokens, opts)

    {:match, line, left, right}
    |> pass_tokens(tokens)
  end

  defp mapper({:cons, 0, value, more} = cons, tokens, opts) do
    {:ok, line} = Keyword.fetch(opts, :line)

    tokens = drop_tokens_to_line(tokens, line)

    case get_list_from_tokens(tokens) do
      {:list, tokens} ->
        # FIXME probably tokens should be returned from list_foldl/3
        list_foldl(cons, tokens, opts)
        |> pass_tokens(tokens)

      {:charlist, tokens} ->
        {:cons, line, value, more}
        |> specify_line(tokens)

      :undefined ->
        {:cons, line, value, more}
        |> pass_tokens(tokens)
    end
  end

  defp mapper({:tuple, 0, elements}, tokens, opts) do
    {:ok, line} = Keyword.fetch(opts, :line)

    tokens
    |> drop_tokens_to_line(line)
    |> get_tuple_from_tokens()
    |> case do
      {:tuple, tokens} ->
        {elements, tokens} = foldl(elements, tokens, opts)
        line = get_line_from_token(hd(tokens))

        {:tuple, line, elements}
        |> pass_tokens(tokens)

      :undefined ->
        {:tuple, line, elements}
        |> pass_tokens(tokens)
    end
  end

  defp mapper({type, 0, value}, tokens, opts)
       when type in [:atom, :char, :float, :integer, :string, :bin] do
    # TODO check what happend for :string
    {:ok, line} = Keyword.fetch(opts, :line)

    {type, line, value}
    |> specify_line(tokens)
  end

  defp mapper(form, tokens, _opts) do
    pass_tokens(form, tokens)
  end

  @doc """
  Iterate over the list in abstract code format and runs mapper on each element 
  """
  @spec list_foldl(form(), [token()], options()) :: form()
  def list_foldl({nil, 0}, _, _), do: {nil, 0}

  def list_foldl({:cons, 0, value, tail}, tokens, opts) do
    {new_value, tokens} = mapper(value, tokens, opts)
    line = elem(new_value, 1)
    {:cons, line, new_value, list_foldl(tail, tokens, opts)}
  end

  @spec get_list_from_tokens([token()]) ::
          {:list, [token()]} | {:charlist, [token()]} | :undefined
  def get_list_from_tokens(tokens) do
    res =
      Enum.drop_while(tokens, fn
        {:"[", _} -> false
        {:list_string, _, _} -> false
        _ -> true
      end)

    case res do
      [{:"[", _} | _] = list -> {:list, list}
      [{:list_string, _, _} | _] = list -> {:charlist, list}
      _ -> :undefined
    end
  end

  @spec get_tuple_from_tokens([token()]) ::
          {:tuple, [token()]} | :undefined
  def get_tuple_from_tokens(tokens) do
    res =
      Enum.drop_while(tokens, fn
        {:"{", _} -> false
        _ -> true
      end)

    case res do
      [{:"{", _} | _] = tuple -> {:tuple, tuple}
      _ -> :undefined
    end
  end

  @spec specify_line(form(), [token()]) :: {form(), [token()]}
  def specify_line(form, tokens) do
    # IO.puts("#{inspect(form)} --- #{inspect(tokens)}")

    [token | tokens] =
      tokens
      |> Enum.drop_while(&(!match_token_to_form(&1, form)))

    {take_loc_from_token(token, form), tokens}
  end

  @spec match_token_to_form(token(), form()) :: boolean()
  defp match_token_to_form({:int, {l1, _, v1}, _}, {:integer, l2, v2}) do
    l2 <= l1 && v1 == v2
  end

  defp match_token_to_form({:char, {l1, _, _}, v1}, {:integer, l2, v2}) do
    l2 <= l1 && v1 == v2
  end

  defp match_token_to_form({:flt, {l1, _, v1}, _}, {:float, l2, v2}) do
    l2 <= l1 && v1 == v2
  end

  defp match_token_to_form({:atom, {l1, _, _}, v1}, {:atom, l2, v2}) do
    l2 <= l1 && v1 == v2
  end

  defp match_token_to_form({:list_string, {l1, _, _}, [v1]}, {:cons, l2, _, _} = cons) do
    v2 = cons_to_charlist(cons)
    # IO.puts("#{inspect v1} -- #{inspect v2}")
    l2 <= l1 && to_charlist(v1) == v2
  end

  defp match_token_to_form(
         {:bin_string, {l1, _, _}, [v1]},
         {:bin, l2, [{:bin_element, _, {:string, _, v2}, :default, :default}]}
       ) do
    # string
    l2 <= l1 && to_charlist(v1) == v2
  end

  defp match_token_to_form({true, {l1, _, _}}, {:atom, l2, true}) do
    l2 <= l1
  end

  defp match_token_to_form({false, {l1, _, _}}, {:atom, l2, false}) do
    l2 <= l1
  end

  defp match_token_to_form(_, _) do
    # IO.puts("#{inspect a} --- #{inspect b}")
    false
  end

  @spec take_loc_from_token(token(), form()) :: form()
  defp take_loc_from_token({:int, {line, _, _}, _}, {:integer, _, value}) do
    {:integer, line, value}
  end

  defp take_loc_from_token({:char, {line, _, _}, _}, {:integer, _, value}) do
    {:integer, line, value}
  end

  defp take_loc_from_token({:flt, {line, _, _}, _}, {:float, _, value}) do
    {:float, line, value}
  end

  defp take_loc_from_token({:atom, {line, _, _}, _}, {:atom, _, value}) do
    {:atom, line, value}
  end

  defp take_loc_from_token({:list_string, {l1, _, _}, _}, {:cons, _, value, tail}) do
    # FIXME propagate line to each list element
    {:cons, l1, value, tail}
  end

  defp take_loc_from_token(
         {:bin_string, {l1, _, _}, _},
         {:bin, _, [{:bin_element, _, {:string, _, v2}, :default, :default}]}
       ) do
    {:bin, l1, [{:bin_element, l1, {:string, l1, v2}, :default, :default}]}
  end

  defp take_loc_from_token({true, {line, _, _}}, {:atom, _, true}) do
    {:atom, line, true}
  end

  defp take_loc_from_token({false, {line, _, _}}, {:atom, _, false}) do
    {:atom, line, false}
  end

  def cons_to_charlist({nil, _}), do: []

  def cons_to_charlist({:cons, _, {:integer, _, value}, tail}) do
    [value | cons_to_charlist(tail)]
  end
end
