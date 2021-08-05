defmodule GradualizerEx.SpecifyErlAst do
  @moduledoc """
  Module adds missing line information to the Erlang abstract code produced 
  from Elixir AST.

  TODO Use anno instead of lines, Attach full location not only the line

  FIXME Optimize tokens searching. Find out why some tokens are dropped 


  NOTE Mapper implements:
  - function [x]
  - fun [x] 
  - clause [x] 
  - case [x]
  - try [x] TODO some variants could be not implemented
  - block [X] 
  - pipe [x]
  - call [x]
  - match [x]
  - op [x]
  - integer [x]
  - float [x]
  - string [x]
  - charlist [x]
  - tuple [X]
  - var [X]
  - list [X] 
  - keyword [X]
  - binary [X] 
  - map [ ] TODO
  - receive [ ] TODO

  - record [ ] TODO record_field, record_index, record_pattern, record
  - named_fun [ ] is named_fun used by elixir? 

  NOTE Elixir expressions to handle or test:
  - list comprehension [X]
  - pipe [X]
  - binary [X]
  - range [ ]
  - receive [ ]
  - maps [ ]
  - record [ ]
  - guards [X]

  """

  import GradualizerEx.Utils

  require Logger

  @type token :: tuple()
  @type form :: tuple()
  @type options :: keyword()

  @doc """

  """
  @spec specify([form()]) :: [form()]
  def specify(forms) do
    # FIXME allow to specify path to file with code
    with {:attribute, 1, :file, {path, 1}} <- hd(forms),
         path <- to_string(path),
         {:ok, code} <- File.read(path),
         {:ok, tokens} <- :elixir.string_to_tokens(String.to_charlist(code), 1, 1, path, []) do
      add_missing_loc_literals(tokens, forms)
    else
      error ->
        IO.puts("Error occured when specifying forms : #{inspect(error)}")
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

  defp mapper({:function, _line, :__info__, _arity, _children} = form, tokens, _opts) do
    pass_tokens(form, tokens)
  end

  defp mapper({:function, line, name, arity, children}, tokens, opts) do
    opts = Keyword.put(opts, :line, line)
    {children, tokens} = foldl(children, tokens, opts)

    {:function, line, name, arity, children}
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

    # TODO figure out how to use this tokens
    # right now it works wrong for generated forms
    {new_condition, _tokens} = mapper(condition, tokens, opts)

    # NOTE use map because generated clauses can be in wrong order
    new_children = Enum.map(children, fn x -> mapper(x, tokens, opts) |> elem(0) end)

    {:case, line, new_condition, new_children}
    |> pass_tokens(tokens)
  end

  defp mapper({:clause, loc, args, guards, children}, tokens, opts) do
    # TODO Adapt the whole module to handle location
    # FIXME handle guards
    # FIXME Handle generated clauses. Right now the literals inherit lines 
    # from the parents without checking them with tokens 
    line = get_line_from_loc(loc)
    opts = Keyword.put(opts, :line, line)

    {guards, tokens} = guards_foldl(guards, tokens, opts)

    # NOTE take a look at this returned tokens
    # 
    {args, _tokens} =
      if !was_generate?(loc) do
        foldl(args, tokens, opts)
      else
        {args, tokens}
      end

    {children, tokens} = children |> foldl(tokens, opts)

    {:clause, line, args, guards, children}
    |> pass_tokens(tokens)
  end

  defp mapper({:block, line, body}, tokens, opts) do
    {:ok, line} = if line == 0, do: Keyword.fetch(opts, :line), else: {:ok, line}

    {body, tokens} = foldl(body, tokens, opts)

    {:block, line, body}
    |> pass_tokens(tokens)
  end

  defp mapper({:match, line, left, right}, tokens, opts) do
    opts = Keyword.put(opts, :line, line)
    {right, tokens} = mapper(right, tokens, opts)

    {:match, line, left, right}
    |> pass_tokens(tokens)
  end

  defp mapper({:cons, line, value, more} = cons, tokens, opts) do
    {:ok, line} =
      case line do
        0 -> Keyword.fetch(opts, :line)
        l -> {:ok, l}
      end

    tokens = drop_tokens_to_line(tokens, line)

    case get_list_from_tokens(tokens) do
      {:list, tokens} ->
        list_foldl(cons, tokens, opts)

      {:keyword, tokens} ->
        list_foldl(cons, tokens, opts)

      {:charlist, tokens} ->
        {:cons, line, value, more}
        |> specify_line(tokens)

      :undefined ->
        Logger.warn("Undefined cons type #{inspect(cons)} -- #{inspect(Enum.take(tokens, 5))}")

        {:cons, line, value, more}
        |> pass_tokens(tokens)
    end
  end

  defp mapper({:tuple, line, elements}, tokens, opts) do
    # TODO find out when line for tuple is 0
    {:ok, line} = if line == 0, do: Keyword.fetch(opts, :line), else: {:ok, line}

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

  defp mapper({:try, line, body, [], catchers, []}, tokens, opts) do
    opts = Keyword.put(opts, :line, line)
    {body, _tokens} = foldl(body, tokens, opts)

    # {catchers, _tokens} = foldl(catchers, tokens, opts)
    catchers = Enum.map(catchers, fn x -> mapper(x, tokens, opts) |> elem(0) end)

    {:try, line, body, [], catchers, []}
    |> pass_tokens(tokens)
  end

  defp mapper({:call, line, name, args}, tokens, opts) do
    opts = Keyword.put(opts, :line, line)
    {args, tokens} = foldl(args, tokens, opts)

    {:call, line, name, args}
    |> pass_tokens(tokens)
  end

  defp mapper({:op, line, op, left, right}, tokens, opts) do
    opts = Keyword.put(opts, :line, line)

    {left, tokens} = mapper(left, tokens, opts)
    {right, tokens} = mapper(right, tokens, opts)

    {:op, line, op, left, right}
    |> pass_tokens(tokens)
  end

  defp mapper({:op, line, op, right}, tokens, opts) do
    opts = Keyword.put(opts, :line, line)

    {right, tokens} = mapper(right, tokens, opts)

    {:op, line, op, right}
    |> pass_tokens(tokens)
  end

  defp mapper({:bin, loc, elements}, tokens, opts) do
    {:ok, loc} =
      case loc do
        0 -> Keyword.fetch(opts, :line)
        _ -> {:ok, loc}
      end

    # TODO find a way to merge this cases
    case elements do
      [{:bin_element, _, {:string, _, _}, :default, :default}] = e ->
        {:bin, loc, e}
        |> specify_line(tokens)

      _ ->
        tokens = cut_tokens_to_bin(tokens, loc)
        {elements, tokens} = bin_element_foldl(elements, tokens, opts)

        {:bin, loc, elements}
        |> pass_tokens(tokens)
    end
  end

  defp mapper({type, _, value}, tokens, opts)
       when type in [:atom, :char, :float, :integer, :string, :bin] do
    # TODO check what happend for :string
    {:ok, line} = Keyword.fetch(opts, :line)

    {type, line, value}
    |> specify_line(tokens)
  end

  defp mapper(skip, tokens, _opts) when elem(skip, 0) in [:fun, :attribute, :var, nil] do
    # NOTE fun - I skipped here checking &name/arity or &module.name/arity
    # skip forms that don't need analysis and do not display warning
    pass_tokens(skip, tokens)
  end

  defp mapper(form, tokens, _opts) do
    Logger.warn("Not found mapper for #{inspect(form)}")
    pass_tokens(form, tokens)
  end

  @doc """
  Adds missing location to the literals in the guards
  """
  @spec guards_foldl([form()], [token()], options()) :: {[form()], [token()]}
  def guards_foldl([], tokens, _opts), do: {[], tokens}

  def guards_foldl(guards, tokens, opts) do
    List.foldl(guards, {[], tokens}, fn
      [guard], {gs, tokens} ->
        {g, ts} = mapper(guard, tokens, opts)
        {[[g] | gs], ts}

      gs, {ags, ts} ->
        Logger.error("Unsupported guards format #{inspect(gs)}")
        {gs ++ ags, ts}
    end)
  end

  def bin_element_foldl(elements, tokens, opts) do
    # {elements, tokens} =
    # List.foldl(elements, {[], tokens}, fn e, {es, tokens} ->
    # {e, tokens} = bin_element(e, tokens, opts)
    # {[e | es], tokens}
    # end)
    # {Enum.reverse(elements), tokens}
    # TODO find a way to restrict tokens only to :bin or maybe unwrap :bin_string token
    elements =
      Enum.map(elements, fn e ->
        {e, _} = bin_element(e, tokens, opts)
        e
      end)

    {elements, tokens}
  end

  def bin_element({:bin_element, line, value, size, tsl}, tokens, opts) do
    opts = Keyword.put(opts, :line, line)
    {value, tokens} = mapper(value, tokens, opts)

    {:bin_element, line, value, size, tsl}
    |> pass_tokens(tokens)
  end

  @doc """
  Iterate over the list in abstract code format and runs mapper on each element 
  """
  @spec list_foldl(form(), [token()], options()) :: form()

  def list_foldl({:cons, line, value, tail}, tokens, opts) do
    {new_value, tokens} = mapper(value, tokens, opts)

    line =
      case line do
        0 -> elem(new_value, 1)
        l -> l
      end

    {tail, tokens} = list_foldl(tail, tokens, opts)

    {:cons, line, new_value, tail}
    |> pass_tokens(tokens)
  end

  def list_foldl(other, tokens, opts), do: mapper(other, tokens, opts)

  @doc """
  Drop tokens to the first conditional occurance. Returns type of the encountered conditional and following tokens.
  """
  @spec get_conditional([token()]) ::
          {:case, [token()]}
          | {:cond, [token()]}
          | {:unless, [token()]}
          | {:if, [token()]}
          | :undefined
  def get_conditional(tokens) do
    conditionals = [:if, :unless, :cond, :case]

    Enum.drop_while(tokens, fn
      {:do_identifier, _, c} -> c not in conditionals
      {:paren_identifier, _, c} -> c not in conditionals
      {:identifier, _, c} -> c not in conditionals
      _ -> true
    end)
    |> case do
      [token | _] = tokens -> {elem(token, 2), tokens}
      _ -> :undefined
    end
  end

  @spec get_list_from_tokens([token()]) ::
          {:list, [token()]} | {:keyword, [token()]} | {:charlist, [token()]} | :undefined
  def get_list_from_tokens(tokens) do
    tokens = flat_tokens(tokens)

    res =
      Enum.drop_while(tokens, fn
        {:"[", _} -> false
        {:list_string, _, _} -> false
        {:kw_identifier, _, id} when id not in [:do] -> false
        _ -> true
      end)

    case res do
      [{:"[", _} | list] -> {:list, list}
      [{:list_string, _, _} | _] = list -> {:charlist, list}
      [{:kw_identifier, _, _} | _] = list -> {:keyword, list}
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
    Logger.debug("#{inspect(form)} --- #{inspect(tokens, limit: :infinity)}")

    res =
      tokens
      |> Enum.drop_while(&(!match_token_to_form(&1, form)))

    case res do
      [token | tokens] ->
        {take_loc_from_token(token, form), tokens}

      [] ->
        Logger.info("Not found - #{inspect(form)}")
        {form, tokens}
    end
  end

  @spec match_token_to_form(token(), form()) :: boolean()
  defp match_token_to_form({:int, {l1, _, v1}, _}, {:integer, l2, v2}) do
    l2 = :erl_anno.line(l2)
    l2 <= l1 && v1 == v2
  end

  defp match_token_to_form({:char, {l1, _, _}, v1}, {:integer, l2, v2}) do
    l2 = :erl_anno.line(l2)
    l2 <= l1 && v1 == v2
  end

  defp match_token_to_form({:flt, {l1, _, v1}, _}, {:float, l2, v2}) do
    l2 = :erl_anno.line(l2)
    l2 <= l1 && v1 == v2
  end

  defp match_token_to_form({:atom, {l1, _, _}, v1}, {:atom, l2, v2}) do
    l2 = :erl_anno.line(l2)
    l2 <= l1 && v1 == v2
  end

  defp match_token_to_form({:list_string, {l1, _, _}, [v1]}, {:cons, l2, _, _} = cons) do
    v2 = cons_to_charlist(cons)
    # IO.puts("#{inspect v1} -- #{inspect v2}")
    l2 <= l1 && to_charlist(v1) == v2
  end

  # BINARY
  defp match_token_to_form(
         {:bin_string, {l1, _, _}, [v1]},
         {:bin, l2, [{:bin_element, _, {:string, _, v2}, :default, :default}]}
       ) do
    # string
    l2 <= l1 && to_charlist(v1) == v2
  end

  # defp match_token_to_form({:bin_string, _, elems}, form) do
  # Enum.any?(elems, &match_token_to_form(&1, form))
  # end

  # defp match_token_to_form({{_, _, nil}, {_, _, nil}, elems}, form) do
  # Enum.any?(elems, &match_token_to_form(&1, form))
  # end

  defp match_token_to_form({:str, _, v}, {:string, _, v1}) do
    v == v1
  end

  # defp match_token_to_form(v, {:string, _, v1}) when is_binary(v) do
  # String.to_charlist(v) == v1
  # end

  # END BIANRY

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

  defp take_loc_from_token({:list_string, {l1, _, _}, _}, {:cons, _, _, _} = charlist) do
    charlist_set_loc(charlist, l1)
  end

  # BINARY
  defp take_loc_from_token(
         {:bin_string, {l1, _, _}, _},
         {:bin, _, [{:bin_element, _, {:string, _, v2}, :default, :default}]}
       ) do
    {:bin, l1, [{:bin_element, l1, {:string, l1, v2}, :default, :default}]}
  end

  # defp take_loc_from_token({:bin_string, _, elems}, form) do
  # elems
  # |> Enum.map(&take_loc_from_token(&1, form))
  # |> Enum.find(&(&1 != nil))
  # end

  # defp take_loc_from_token({{_, _, nil}, {_, _, nil}, elems}, form) do
  # elem = Enum.find(elems, &match_token_to_form(&1, form))
  # take_loc_from_token(elem, form)
  # end

  # defp take_loc_from_token(v, {:string, loc, v2}) when is_binary(v) do
  # {:string, loc, v2}
  # end

  defp take_loc_from_token({:str, _, _}, {:string, loc, v2}) do
    {:string, loc, v2}
  end

  # END BINARY

  defp take_loc_from_token({true, {line, _, _}}, {:atom, _, true}) do
    {:atom, line, true}
  end

  defp take_loc_from_token({false, {line, _, _}}, {:atom, _, false}) do
    {:atom, line, false}
  end

  defp take_loc_from_token(_, _), do: nil

  def cons_to_charlist({nil, _}), do: []

  def cons_to_charlist({:cons, _, {:integer, _, value}, tail}) do
    [value | cons_to_charlist(tail)]
  end

  def charlist_set_loc({:cons, _, {:integer, _, value}, tail}, loc) do
    {:cons, loc, {:integer, loc, value}, charlist_set_loc(tail, loc)}
  end

  def charlist_set_loc({nil, loc}, _), do: {nil, loc}
end
