defmodule GradualizerEx.SpecifyErlAst do
  @moduledoc """
  Module adds missing line information to the Erlang abstract code produced 
  from Elixir AST.
  """

  @type token :: tuple()
  @type form :: tuple()
  @type options :: keyword()

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

  defp mapper({:clause, line, args, [], children}, tokens, opts) do
    opts = Keyword.put(opts, :line, line)
    {children, tokens} = foldl(children, tokens, opts)

    {:clause, line, args, [], children}
    |> pass_tokens(tokens)
  end

  defp mapper({:match, line, left, right}, tokens, opts) do
    opts = Keyword.put(opts, :line, line)
    {right, tokens} = mapper(right, tokens, opts)

    {:match, line, left, right}
    |> pass_tokens(tokens)
  end

  defp mapper({:integer, 0, value}, tokens, opts) do
    {:ok, line} = Keyword.fetch(opts, :line)

    {:integer, line, value}
    |> specify_line(tokens)
  end

  defp mapper({:atom, 0, value}, tokens, opts) do
    {:ok, line} = Keyword.fetch(opts, :line)

    {:atom, line, value}
    |> specify_line(tokens)
  end

  defp mapper(form, tokens, _opts) do
    pass_tokens(form, tokens)
  end

  @spec specify_line(form(), [token()]) :: {form(), [token()]}
  defp specify_line(form, tokens) do
    [token | tokens] =
      tokens
      |> Enum.drop_while(&(!match_token_to_form(&1, form)))

    {take_loc_from_token(token, form), tokens}
  end

  @spec match_token_to_form(token(), form()) :: boolean()
  defp match_token_to_form({:int, {l1, _, _}, v1}, {:integer, l2, v2}) do
    l2 <= l1 && v1 == to_charlist(v2)
  end

  defp match_token_to_form({:atom, {l1, _, _}, v1}, {:atom, l2, v2}) do
    l2 <= l1 && v1 == v2
  end

  defp match_token_to_form(_, _) do
    false
  end

  @spec take_loc_from_token(token(), form()) :: form()
  defp take_loc_from_token({:int, {line, _, _}, _}, {:integer, _, value}) do
    {:integer, line, value}
  end

  defp take_loc_from_token({:atom, {line, _, _}, _}, {:atom, _, value}) do
    {:atom, line, value}
  end

  # def ensure_line(form, opts) do
  # {:ok, tokens} = Keyword.fetch(opts, :tokens)
  # scopes = mark_scopes(tokens)
  # find_in_scopes(scopes, form)
  # end

  # def find_in_scopes(scopes, form) do
  # line = elem(form, 1)

  # scopes =
  # scopes
  # |> Enum.drop_while(fn {_, token} ->
  # {current_line, _, _} = elem(token, 1)
  # current_line < line
  # end)

  # {scope_num, _} = hd(scopes)

  # scopes
  ## |> Enum.drop_while(fn {s, _} -> s == scope_num end)
  # |> Enum.take_while(fn {s, _} -> s == scope_num end)
  # |> Enum.reverse()
  # |> Enum.find(fn {_, t} -> match_token_to_form(t, form) end)
  # |> process(form)
  # end

  # def process({_, token}, form), do: take_loc_from_token(token, form)
  # def process(nil, form), do: form

  # def mark_scopes(tokens) do
  # %{res: res} =
  # Enum.reduce(tokens, %{scope: 0, res: []}, fn
  ## {:do, _} = token, acc ->
  ## acc = Map.put(acc, :scope, acc.scope + 1)
  ## Map.put(acc, :res, [{acc.scope, token} | acc.res])

  ## {:end, _} = token, acc ->
  ## acc = Map.put(acc, :scope, acc.scope - 1)
  ## Map.put(acc, :res, [{acc.scope, token} | acc.res])

  # {:identifier, _, :def} = token, acc ->
  # acc = Map.put(acc, :scope, acc.scope + 1)
  # Map.put(acc, :res, [{acc.scope, token} | acc.res])

  # token, acc ->
  # Map.put(acc, :res, [{acc.scope, token} | acc.res])
  # end)

  # Enum.reverse(res)
  # end

  # def localyze({:identifier, _, :def}) do
  # end

  # def localyze({:do, _}) do
  # end

  # def localyze({:eol, _}) do
  # end

  # def localyze({:end, _}) do
  # end

  # def restrict_search_area(tokens, {_, line, _}, limit \\ 1) do
  # tokens
  # |> Enum.drop_while(fn token ->
  # {current_line, _, _} = elem(toke, 1)
  # current_line < line
  # end)
  # |> Enum.take_while(fn token ->

  # end)

  # range = (line - limit)..(line + limit)

  # Enum.filter(tokens, fn
  # {_, {line, _, _}, _} -> line in range
  # _ -> false
  # end)
  # end
end
