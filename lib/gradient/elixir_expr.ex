defmodule Gradient.ElixirExpr do
  @moduledoc """
  Module formats the Erlang abstract expressions to the Elixir code.

  FIXME
  - nil ([]) line is not specified by AstSpecifier

  TODO Elixir
  - [ ] structs
  - [ ] raise

  TODO Erlang
  - [x] bitstring comprehension
  - [x] bitstring constructor
  - [x] list comprehension
    Elixir don't use :lc expression. Even simple lc is stored in AST as below:
      - Elixir source:
          for n <- [1, 2, 3], do: n
      - Stored in abstract code as:
          :lists.reverse(Enum.reduce([1, 2, 3], [], fn n, acc -> [n | acc] end))

  - [x] case expression / TODO clauses
  - [x] fun expression / TODO clauses
  - [x] receive expression / TODO clauses
  - [ ] TODO try expression

  - if expression / not use by Elixir (Elixir uses case in abstract code)
  - record / not use by Elixir, probably can be skipped
  """

  @spec pretty_print_body([:erl_parse.abstract_expr()]) :: [String.t()]
  def pretty_print_body(exprs) do
    Enum.map(exprs, &pretty_print/1)
  end

  @spec pretty_print(:erl_parse.abstract_expr()) :: String.t()
  def pretty_print({:atom, _, l}) do
    ":" <> Atom.to_string(l)
  end

  def pretty_print({:char, _, l}) do
    "?" <> List.to_string([l])
  end

  def pretty_print({:float, _, l}) do
    Float.to_string(l)
  end

  def pretty_print({:integer, _, l}) do
    Integer.to_string(l)
  end

  def pretty_print({:string, _, charlist}) do
    "\"" <> List.to_string(charlist) <> "\""
  end

  def pretty_print({:remote, _, module, fun}) do
    module = pretty_print(module)
    fun = pretty_print(fun)
    module <> "." <> fun
  end

  def pretty_print({:block, _, body}) do
    # TODO maybe add indent?
    body
    |> pretty_print_body()
    |> Enum.join("\n")
  end

  def pretty_print({:catch, _, expr}) do
    pretty_print(expr)
  end

  def pretty_print({:cons, _, _, _} = cons) do
    case cons_to_int_list(cons) do
      {:ok, l} ->
        inspect(l)

      :error ->
        items =
          pp_cons(cons)
          |> Enum.join(", ")

        "[" <> items <> "]"
    end
  end

  def pretty_print({:fun, _, {:function, name, arity}}) do
    name = pretty_print(name)
    arity = pretty_print(arity)
    "&#{name}/#{arity}"
  end

  def pretty_print({:fun, _, {:function, module, name, arity}}) do
    module = pretty_print(module)
    name = pretty_print(name)
    arity = pretty_print(arity)
    "#{module}.&#{name}/#{arity}"
  end

  def pretty_print({:fun, _, {:clauses, clauses}}) do
    # print all as a one line
    clauses = Enum.map(clauses, &pretty_print_clause/1) |> Enum.join("; ")
    "fn " <> clauses <> " end"
  end

  def pretty_print({:call, _, name, args}) do
    args =
      Enum.map(args, &pretty_print/1)
      |> Enum.join(" ,")

    name = pretty_print(name)
    name <> "(" <> args <> ")"
  end

  def pretty_print({:map, _, pairs}) do
    pairs = Enum.map(pairs, &format_map_element/1) |> Enum.join(", ")
    "%{" <> pairs <> "}"
  end

  def pretty_print({:map, _, map, pairs}) do
    pairs = Enum.map(pairs, &format_map_element/1) |> Enum.join(", ")
    map = pretty_print(map)
    "%{" <> map <> " | " <> pairs <> "}"
  end

  def pretty_print({:match, _, var, expr}) do
    pretty_print(var) <> " = " <> pretty_print(expr)
  end

  def pretty_print({nil, _}) do
    "[]"
  end

  def pretty_print({:op, _, op, type}) do
    Atom.to_string(op) <> " " <> pretty_print(type)
  end

  def pretty_print({:op, _, op, left_type, right_type}) do
    operator = " " <> Atom.to_string(op) <> " "
    pretty_print(left_type) <> operator <> pretty_print(right_type)
  end

  def pretty_print({:tuple, _, elements}) do
    elements_str = Enum.map(elements, &pretty_print(&1)) |> Enum.join(", ")
    "{" <> elements_str <> "}"
  end

  def pretty_print({:var, _, t}) do
    # FIXME remove number from variable
    Atom.to_string(t)
  end

  def pretty_print({:bin, _, [{:bin_element, _, {:string, _, value}, :default, :default}]}) do
    "\"" <> to_string(value) <> "\""
  end

  def pretty_print({:bin, _, elements}) do
    elements
    |> Enum.map(fn e -> pretty_print_bin_element(e) end)
    |> Enum.join(", ")
  end

  def pretty_print({t, _, expr0, quantifiers}) when t in [:bc, :lc] do
    expr0 = pretty_print(expr0)
    "for #{quantifiers}, do: #{expr0}"
  end

  # Quantifiers
  def pretty_print({type, _, pattern, expr}) when type in [:genenrate, :b_generate] do
    pretty_print(pattern) <> " <- " <> pretty_print(expr)
  end

  def pretty_print({:case, _, condition, clauses}) do
    # print all as a one line
    clauses = Enum.map(clauses, &pretty_print_clause/1) |> Enum.join("; ")
    "case " <> pretty_print(condition) <> " do " <> clauses <> " end"
  end

  def pretty_print({:receive, _, clauses}) do
    "receive" <> pretty_clauses(clauses) <> "end"
  end

  def pretty_print({:receive, _, clauses, after_value, _after_body}) do
    pclauses = pretty_clauses(clauses)
    pvalue = pretty_print(after_value)
    "receive " <> pclauses <> "after " <> pvalue <> " -> ... end"
  end

  def pretty_print({:try, _, _body, _else_block, _catchers, _after_block}) do
    "try do ... end"
  end

  # def pretty_print(expr) do
  # :erl_pp.expr(expr)
  # |> :erlang.iolist_to_binary()
  # end

  # Private

  def pretty_clauses(clauses) do
    Enum.map(clauses, &pretty_print_clause/1) |> Enum.join("; ")
  end

  def pretty_print_clause({:clause, _, _args, _guards, _body}) do
    #
    "..."
  end

  defp pretty_print_bin_element({:bin_element, _, value, size, tsl}) do
    value = pretty_print(value)

    bin_set_tsl(tsl)
    |> bin_set_size(size)
    |> bin_set_value(value)
  end

  defp bin_set_value("", value) do
    value
  end

  defp bin_set_value(sufix, value) do
    value <> "::" <> sufix
  end

  defp bin_set_size("", size) do
    Integer.to_string(size)
  end

  defp bin_set_size(tsl, :default) do
    tsl
  end

  defp bin_set_size(tsl, size) do
    tsl <> "-size(" <> Integer.to_string(size) <> ")"
  end

  defp bin_set_tsl(:default) do
    ""
  end

  defp bin_set_tsl(tsl) do
    Atom.to_string(tsl)
  end

  @spec format_map_element(tuple()) :: String.t()
  def format_map_element({field, _, key, value})
      when field in [:map_field_assoc, :map_field_exact] do
    key = pretty_print(key)
    value = pretty_print(value)
    key <> " => " <> value
  end

  @spec cons_to_int_list(tuple()) :: {:ok, [integer()]} | :error
  def cons_to_int_list(cons) do
    try do
      {:ok, try_int_list_(cons)}
    catch
      nil ->
        :error
    end
  end

  defp try_int_list_({nil, _}), do: []
  defp try_int_list_({:cons, _, {:integer, _, val}, t}), do: [val | try_int_list_(t)]
  defp try_int_list_(_), do: throw(nil)

  defp pp_cons({nil, _}), do: []
  defp pp_cons({:var, _, _} = v), do: [pretty_print(v)]
  defp pp_cons({:cons, _, h, t}), do: [pretty_print(h) | pp_cons(t)]
end
