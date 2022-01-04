defmodule Gradient.ElixirExpr do
  @moduledoc """
  Module formats the Erlang abstract expressions to the Elixir code.

  FIXME
  - nil ([]) line is not specified by AstSpecifier

  TODO Elixir
  - [ ] structs
  - [ ] raise
  - [ ] call Erlang correctly e.g. `:erlang.error` (now is `erlang.error`) (reuse code from Elixir Type)
  - [ ] format Elixir atoms and boolean correctly (reuse code from ElixirType)

  TODO Erlang
  - [x] bitstring comprehension
  - [x] bitstring constructor
  - [x] list comprehension
    Elixir doesn't use the :lc expression. Even a simple list comprehension is stored in the AST as below:
      - Elixir source:
          for n <- [1, 2, 3], do: n
      - Stored in abstract code as:
          :lists.reverse(Enum.reduce([1, 2, 3], [], fn n, acc -> [n | acc] end))

  - [x] case expression
  - [x] fun expression
  - [x] receive expression
  - [x] try expression
  - [ ] support guards

  - if expression / not used by Elixir (Elixir uses case in abstract code)
  - record / not used by Elixir, probably can be skipped
  - block / not produced by Elixir, I think
  - catch / not produced by Elixir, I think
  """

  alias Gradient.ElixirFmt

  @type expr :: :erl_parse.abstract_expr()
  @type clause :: :erl_parse.abstract_clause()

  @doc """
  Format abstract expressions to Elixir code
  """
  @spec pretty_print(expr() | [expr()]) :: String.t()
  def pretty_print(exprs) when is_list(exprs) do
    exprs
    |> Enum.map(&pretty_print/1)
    |> Enum.join("; ")
  end

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
    "&#{name}/#{arity}"
  end

  def pretty_print({:fun, _, {:function, module, name, arity}}) do
    module = ElixirFmt.parse_module(module)
    name = pretty_print(name)
    arity = pretty_print(arity)
    "&#{module}#{name}/#{arity}"
  end

  def pretty_print({:fun, _, {:clauses, clauses}}) do
    # print all as a one line
    clauses = pp_clauses(clauses)
    "fn " <> clauses <> " end"
  end

  def pretty_print({:call, _, name, args}) do
    args =
      Enum.map(args, &pretty_print/1)
      |> Enum.join(" ,")

    pp_name(name) <> "(" <> args <> ")"
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
  def pretty_print({type, _, pattern, expr}) when type in [:generate, :b_generate] do
    pretty_print(pattern) <> " <- " <> pretty_print(expr)
  end

  def pretty_print({:case, _, condition, clauses}) do
    # print all as a one line
    clauses = pp_clauses(clauses)
    "case " <> pretty_print(condition) <> " do " <> clauses <> " end"
  end

  def pretty_print({:receive, _, clauses}) do
    "receive" <> pp_clauses(clauses) <> "end"
  end

  def pretty_print({:receive, _, clauses, after_value, _after_body}) do
    pclauses = pp_clauses(clauses)
    pvalue = pretty_print(after_value)
    "receive " <> pclauses <> "after " <> pvalue <> " -> ... end"
  end

  def pretty_print({:try, _, body, else_block, catchers, after_block}) do
    "try do "
    |> append_try_body(body)
    |> maybe_try_else(else_block)
    |> maybe_try_catch(catchers)
    |> maybe_try_after(after_block)
    |> Kernel.<>(" end")
  end

  # def pretty_print(expr) do
  # :erl_pp.expr(expr)
  # |> :erlang.iolist_to_binary()
  # end

  @doc """
  Format abstract clauses to Elixir code
  """
  @spec pp_clauses([clause()], :case | :catch) :: String.t()
  def pp_clauses(clauses, type \\ :case)

  def pp_clauses(clauses, :case) do
    Enum.map(clauses, &pp_case_clause/1) |> Enum.join("; ")
  end

  def pp_clauses(clauses, :catch) do
    Enum.map(clauses, &pp_catch_clause/1) |> Enum.join("; ")
  end

  def pp_guards([]) do
    ""
  end

  def pp_guards(_) do
    # FIXME implement guards pretty printing
    " when ..."
  end

  # Private

  defp pp_catch_clause({:clause, _, [{:tuple, _, [type, var, _stacktrace]}], guards, body}) do
    # rescue/catch clause
    # FIXME support guards, support stacktrace?

    case get_error_type(guards) do
      {:ok, error_type} ->
        # rescue
        {var2, body2} = get_error_var(var, body)

        pretty_print(type) <>
          ", %" <>
          pretty_print(error_type) <>
          "{} = " <> pretty_print(var2) <> " -> " <> pretty_print(body2)

      :not_found ->
        # throw
        pretty_print(type) <> ", " <> pretty_print(var) <> " -> " <> pretty_print(body)
    end
  end

  defp pp_case_clause({:clause, _, patterns, guards, body}) do
    # FIXME support guards
    patterns =
      patterns
      |> Enum.map(&pretty_print/1)
      |> Enum.join(", ")

    patterns <> pp_guards(guards) <> " -> " <> pretty_print(body)
  end

  defp append_try_body(res, body) do
    res <> pretty_print(body)
  end

  defp maybe_try_else(res, []) do
    res
  end

  defp maybe_try_else(res, else_block) do
    res <> "; else " <> pp_clauses(else_block)
  end

  defp maybe_try_catch(res, []), do: res
  defp maybe_try_catch(res, clauses), do: res <> "; catch " <> pp_clauses(clauses, :catch)

  defp maybe_try_after(res, []) do
    res
  end

  defp maybe_try_after(res, else_block) do
    res <> "; after " <> pp_clauses(else_block)
  end

  def get_error_type([[{:op, _, :andalso, {:op, _, :==, _, error_type}, _}]]) do
    {:ok, error_type}
  end

  def get_error_type(_) do
    :not_found
  end

  def get_error_var({:var, _, v}, [{:match, _, user_var, {:var, _, v}} | body_tail]) do
    {user_var, body_tail}
  end

  def get_error_var(var, body) do
    {var, body}
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

  defp pp_name({:remote, _, {:atom, _, m}, {:atom, _, n}}),
    do: ElixirFmt.parse_module(m) <> to_string(n)

  defp pp_name({:atom, _, n}), do: to_string(n)
end
