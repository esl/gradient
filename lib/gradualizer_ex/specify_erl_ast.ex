defmodule GradualizerEx.SpecifyErlAst do
  @moduledoc """
  Module adds missing line information to the Erlang abstract code produced 
  from Elixir AST.

  FIXME Optimize tokens searching. Find out why some tokens are dropped 

  NOTE Mapper implements:
  - function [x]
  - fun [x] 
  - clause [x] 
  - case [x]
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
  - map [X] 
  - try [x] TODO probably some variants could be not implemented
  - receive [X] 
  - record [X] elixir don't use it record_field, record_index, record_pattern, record

  - remote [ ] TODO maybe handle this call case
  - named_fun [ ] is named_fun used by elixir? 

  NOTE Elixir expressions to handle or test:
  - list comprehension [X]
  - binary [X]
  - maps [X]
  - struct [X]
  - pipe [ ] TODO decide how to search for line in reversed form order 
  - range [ ] TODO write test
  - receive [X] 
  - record [X] 
  - guards [X]

  """

  import GradualizerEx.Utils

  require Logger

  @type token :: tuple()
  @type tokens :: [tuple()]
  @type form ::
          :erl_parse.abstract_clause()
          | :erl_parse.abstract_expr()
          | :erl_parse.abstract_form()
          | :erl_parse.abstract_type()
  @type forms :: [form()]
  @type options :: keyword()

  @doc """

  """
  @spec specify(nonempty_list(:erl_parse.abstract_form())) :: [:erl_parse.abstract_form()]
  def specify(forms) do
    # FIXME allow to specify path to file with code
    with {:attribute, 1, :file, {path, 1}} <- hd(forms),
         path <- to_string(path),
         {:ok, code} <- File.read(path),
         {:ok, tokens} <- :elixir.string_to_tokens(String.to_charlist(code), 1, 1, path, []) do
      add_missing_loc_literals(forms, tokens)
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
  @spec add_missing_loc_literals([:erl_parse.abstract_form()], tokens()) :: [
          :erl_parse.abstract_form()
        ]
  def add_missing_loc_literals(forms, tokens) do
    opts = []
    Enum.map(forms, fn x -> mapper(x, tokens, opts) |> elem(0) end)
  end

  @spec foldl([form()], [token()], options()) :: {[form()], [token()]}
  defp foldl(forms, tokens, opts) do
    List.foldl(forms, {[], tokens}, fn form, {acc_forms, acc_tokens} ->
      {res_form, res_tokens} = mapper(form, acc_tokens, opts)
      {[res_form | acc_forms], res_tokens}
    end)
    |> update_in([Access.elem(0)], &Enum.reverse/1)
  end

  @spec pass_tokens(any(), tokens()) :: {any(), tokens()}
  defp pass_tokens(form, tokens) do
    {form, tokens}
  end

  @spec mapper(form(), [token()], options()) :: {form(), [token()]}
  defp mapper(form, tokens, opts)

  defp mapper({:function, _line, :__info__, _arity, _children} = form, tokens, _opts) do
    pass_tokens(form, tokens)
  end

  defp mapper({:function, anno, name, arity, clauses}, tokens, opts) do
    {clauses, tokens} = foldl(clauses, tokens, opts)

    {:function, anno, name, arity, clauses}
    |> pass_tokens(tokens)
  end

  defp mapper({:fun, anno, {:clauses, clauses}}, tokens, opts) do
    {clauses, tokens} = foldl(clauses, tokens, opts)

    {:fun, anno, {:clauses, clauses}}
    |> pass_tokens(tokens)
  end

  defp mapper({:case, anno, condition, clauses}, tokens, opts) do
    # NOTE In Elixir `if`, `case` and `cond` statements are represented 
    # as a `case` in abstract code.
    line = :erl_anno.line(anno)
    opts = Keyword.put(opts, :line, line)

    # TODO figure out how to use this tokens
    # right now it works wrong for generated forms
    {new_condition, _tokens} = mapper(condition, tokens, opts)

    opts =
      case get_conditional(tokens, line) do
        {type, _} when type in [:case, :with] ->
          Keyword.put(opts, :case_type, :case)

        {type, _} when type in [:cond, :if, :unless] ->
          Keyword.put(opts, :case_type, :gen)

        :undefined ->
          Keyword.put(opts, :case_type, :gen)
      end

    # NOTE use map because generated clauses can be in wrong order
    clauses = Enum.map(clauses, fn x -> mapper(x, tokens, opts) |> elem(0) end)

    {:case, anno, new_condition, clauses}
    |> pass_tokens(tokens)
  end

  defp mapper({:clause, anno, args, guards, children}, tokens, opts) do
    # FIXME Handle generated clauses. Right now the literals inherit lines 
    # from the parents without checking them with tokens 
    line = :erl_anno.line(anno)
    opts = Keyword.put(opts, :line, line)
    case_type = Keyword.get(opts, :case_type, :case)

    tokens = drop_tokens_to_line(tokens, line)

    if case_type == :case do
      {guards, tokens} = guards_foldl(guards, tokens, opts)

      # NOTE take a look at this returned tokens
      # 
      {args, _tokens} =
        if not :erl_anno.generated(anno) do
          foldl(args, tokens, opts)
        else
          {args, tokens}
        end

      {children, tokens} = children |> foldl(tokens, opts)

      {:clause, anno, args, guards, children}
      |> pass_tokens(tokens)
    else
      {children, tokens} = children |> foldl(tokens, opts)

      {:clause, anno, args, guards, children}
      |> pass_tokens(tokens)
    end
  end

  defp mapper({:block, anno, body}, tokens, opts) do
    {:ok, line, _} = get_line(anno, opts)
    anno = :erl_anno.set_line(line, anno)

    {body, tokens} = foldl(body, tokens, opts)

    {:block, anno, body}
    |> pass_tokens(tokens)
  end

  defp mapper({:match, anno, left, right}, tokens, opts) do
    line = :erl_anno.line(anno)
    opts = Keyword.put(opts, :line, line)
    {left, tokens} = mapper(left, tokens, opts)
    {right, tokens} = mapper(right, tokens, opts)

    {:match, anno, left, right}
    |> pass_tokens(tokens)
  end

  defp mapper({:map, anno, pairs}, tokens, opts) do
    {pairs, tokens} = map_foldl(pairs, tokens, opts)

    {:map, anno, pairs}
    |> pass_tokens(tokens)
  end

  defp mapper({:map, anno, map, pairs}, tokens, opts) do
    # update pattern
    {map, tokens} = mapper(map, tokens, opts)
    {pairs, tokens} = map_foldl(pairs, tokens, opts)

    {:map, anno, map, pairs}
    |> pass_tokens(tokens)
  end

  defp mapper({:cons, anno, value, more} = cons, tokens, opts) do
    {:ok, line, _} = get_line(anno, opts)
    anno = :erl_anno.set_line(line, anno)

    tokens = drop_tokens_to_line(tokens, line)

    case get_list_from_tokens(tokens) do
      {:list, tokens} ->
        list_foldl(cons, tokens, opts)

      {:keyword, tokens} ->
        list_foldl(cons, tokens, opts)

      {:charlist, tokens} ->
        {:cons, anno, value, more}
        |> specify_line(tokens)

      :undefined ->
        Logger.warn("Undefined cons type #{inspect(cons)} -- #{inspect(Enum.take(tokens, 5))}")

        {:cons, anno, value, more}
        |> pass_tokens(tokens)
    end
  end

  defp mapper({:tuple, anno, elements}, tokens, opts) do
    {:ok, line, has_line?} = get_line(anno, opts)
    anno = :erl_anno.set_line(line, anno)
    opts = Keyword.put(opts, :line, line)

    tokens
    |> drop_tokens_to_line(line)
    |> get_tuple_from_tokens()
    |> case do
      {:tuple, tokens} ->
        {anno, opts} =
          if not has_line? do
            line = get_line_from_token(hd(tokens))
            {:erl_anno.set_line(line, anno), Keyword.put(opts, :line, line)}
          else
            {anno, opts}
          end

        {elements, tokens} = foldl(elements, tokens, opts)

        {:tuple, anno, elements}
        |> pass_tokens(tokens)

      :undefined ->
        {:tuple, anno, elements}
        |> pass_tokens(tokens)
    end
  end

  defp mapper({:receive, anno, clauses}, tokens, opts) do
    line = :erl_anno.line(anno)
    opts = Keyword.put(opts, :line, line)

    {clauses, tokens} = foldl(clauses, tokens, opts)

    {:receive, anno, clauses}
    |> pass_tokens(tokens)
  end

  defp mapper({:receive, anno, clauses, after_val, after_block}, tokens, opts) do
    line = :erl_anno.line(anno)
    opts = Keyword.put(opts, :line, line)

    # FIXME Use when losing tokens will be fixed
    {clauses, _tokens} = foldl(clauses, tokens, opts)
    {after_val, tokens} = mapper(after_val, tokens, opts)
    {after_block, tokens} = foldl(after_block, tokens, opts)

    {:receive, anno, clauses, after_val, after_block}
    |> pass_tokens(tokens)
  end

  defp mapper({:try, anno, body, [], catchers, []}, tokens, opts) do
    line = :erl_anno.line(anno)
    opts = Keyword.put(opts, :line, line)
    {body, _tokens} = foldl(body, tokens, opts)

    # {catchers, _tokens} = foldl(catchers, tokens, opts)
    catchers = Enum.map(catchers, fn x -> mapper(x, tokens, opts) |> elem(0) end)

    {:try, anno, body, [], catchers, []}
    |> pass_tokens(tokens)
  end

  defp mapper({:call, anno, name, args}, tokens, opts) do
    line = :erl_anno.line(anno)
    opts = Keyword.put(opts, :line, line)
    {args, tokens} = foldl(args, tokens, opts)

    {:call, anno, name, args}
    |> pass_tokens(tokens)
  end

  defp mapper({:op, anno, op, left, right}, tokens, opts) do
    line = :erl_anno.line(anno)
    opts = Keyword.put(opts, :line, line)

    {left, tokens} = mapper(left, tokens, opts)
    {right, tokens} = mapper(right, tokens, opts)

    {:op, anno, op, left, right}
    |> pass_tokens(tokens)
  end

  defp mapper({:op, anno, op, right}, tokens, opts) do
    line = :erl_anno.line(anno)
    opts = Keyword.put(opts, :line, line)

    {right, tokens} = mapper(right, tokens, opts)

    {:op, anno, op, right}
    |> pass_tokens(tokens)
  end

  defp mapper({:bin, anno, elements}, tokens, opts) do
    {:ok, line, _} = get_line(anno, opts)
    anno = :erl_anno.set_line(line, anno)

    # TODO find a way to merge this cases
    case elements do
      [{:bin_element, _, {:string, _, _}, :default, :default}] = e ->
        {:bin, anno, e}
        |> specify_line(tokens)

      _ ->
        tokens = cut_tokens_to_bin(tokens, line)
        {elements, tokens} = bin_element_foldl(elements, tokens, opts)

        {:bin, anno, elements}
        |> pass_tokens(tokens)
    end
  end

  defp mapper({type, anno, value}, tokens, opts)
       when type in [:atom, :char, :float, :integer, :string, :bin] do
    # TODO check what happend for :string
    {:ok, line} = Keyword.fetch(opts, :line)
    anno = :erl_anno.set_line(line, anno)

    {type, anno, value}
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

  def map_foldl(pairs, tokens, opts) do
    List.foldl(pairs, {[], tokens}, fn p, {ps, ts} ->
      {p, ts} = map_element(p, ts, opts)
      {[p | ps], ts}
    end)
    |> update_in([Access.elem(0)], &Enum.reverse/1)
  end

  def map_element({field, anno, key, value}, tokens, opts)
      when field in [:map_field_assoc, :map_field_exact] do
    line = :erl_anno.line(anno)
    opts = Keyword.put(opts, :line, line)

    {key, tokens} = mapper(key, tokens, opts)
    {value, tokens} = mapper(value, tokens, opts)

    {field, anno, key, value}
    |> pass_tokens(tokens)
  end

  def bin_element_foldl(elements, tokens, opts) do
    tokens = flat_tokens(tokens)

    List.foldl(elements, {[], tokens}, fn e, {es, ts} ->
      {e, ts} = bin_element(e, ts, opts)
      {[e | es], ts}
    end)
    |> update_in([Access.elem(0)], &Enum.reverse/1)
  end

  def bin_element({:bin_element, anno, value, size, tsl}, tokens, opts) do
    {:ok, line, _} = get_line(anno, opts)
    anno = :erl_anno.set_line(line, anno)
    opts = Keyword.put(opts, :line, line)
    {value, tokens} = mapper(value, tokens, opts)

    {:bin_element, anno, value, size, tsl}
    |> pass_tokens(tokens)
  end

  @doc """
  Iterate over the list in abstract code format and runs mapper on each element 
  """
  @spec list_foldl(form(), [token()], options()) :: {form(), tokens()}

  def list_foldl({:cons, anno, value, tail}, [token | _] = tokens, opts) do
    line = get_line_from_token(token)
    opts = Keyword.put(opts, :line, line)
    anno = :erl_anno.set_line(line, anno)

    {new_value, tokens} = mapper(value, tokens, opts)

    {tail, tokens} = list_foldl(tail, tokens, opts)

    {:cons, anno, new_value, tail}
    |> pass_tokens(tokens)
  end

  def list_foldl(other, tokens, opts), do: mapper(other, tokens, opts)

  @doc """
  Drop tokens to the first conditional occurance. Returns type of the encountered conditional and following tokens.
  """
  @spec get_conditional([token()], integer()) ::
          {:case, [token()]}
          | {:cond, [token()]}
          | {:unless, [token()]}
          | {:if, [token()]}
          | {:with, [token()]}
          | :undefined
  def get_conditional(tokens, line) do
    conditionals = [:if, :unless, :cond, :case, :with]

    Enum.drop_while(tokens, fn
      {:do_identifier, _, c} -> c not in conditionals
      {:paren_identifier, _, c} -> c not in conditionals
      {:identifier, _, c} -> c not in conditionals
      _ -> true
    end)
    |> case do
      [token | _] = tokens when elem(elem(token, 1), 0) == line -> {elem(token, 2), tokens}
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
      [{:"[", _} | _] = list -> {:list, list}
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
        {:kw_identifier, _, _} -> false
        _ -> true
      end)

    case res do
      [{:"{", _} | _] = tuple -> {:tuple, tuple}
      [{:kw_identifier, _, _} | _] = tuple -> {:tuple, tuple}
      _ -> :undefined
    end
  end

  @spec specify_line(form(), [token()]) :: {form(), [token()]}
  # def specify_line(form, []), do: raise("ehh -- #{inspect form}")
  def specify_line(form, tokens) do
    if not :erl_anno.generated(elem(form, 1)) do
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
    else
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

  defp match_token_to_form({:alias, {l1, _, _}, v1}, {:atom, l2, v2}) do
    l2 = :erl_anno.line(l2)
    l2 <= l1 && v1 == v2
  end

  defp match_token_to_form({:kw_identifier, {l1, _, _}, v1}, {:atom, l2, v2}) do
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

  defp match_token_to_form({:str, _, v}, {:string, _, v1}) do
    to_charlist(v) == v1
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

  defp take_loc_from_token({:alias, {line, _, _}, _}, {:atom, _, value}) do
    {:atom, line, value}
  end

  defp take_loc_from_token({:kw_identifier, {line, _, _}, _}, {:atom, _, value}) do
    {:atom, line, value}
  end

  defp take_loc_from_token({:list_string, {l1, _, _}, _}, {:cons, _, _, _} = charlist) do
    charlist_set_loc(charlist, l1)
  end

  defp take_loc_from_token(
         {:bin_string, {l1, _, _}, _},
         {:bin, _, [{:bin_element, _, {:string, _, v2}, :default, :default}]}
       ) do
    {:bin, l1, [{:bin_element, l1, {:string, l1, v2}, :default, :default}]}
  end

  defp take_loc_from_token({:str, _, _}, {:string, loc, v2}) do
    {:string, loc, v2}
  end

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

  # @spec get_line(any(), options()) :: {:ok, \c 
  def get_line(anno, opts) do
    case :erl_anno.line(anno) do
      0 ->
        case Keyword.fetch(opts, :line) do
          {:ok, line} -> {:ok, line, false}
          err -> err
        end

      line ->
        {:ok, line, true}
    end
  end
end
