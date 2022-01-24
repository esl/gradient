defmodule Gradient.ElixirExpr do
  @moduledoc """
  Module formats the Erlang abstract expressions to the Elixir code.

  FIXME
  - nil ([]) line is not specified by AstSpecifier

  TODO Elixir
  - [x] structs
  - [x] print true/false case as if?
  - [x] print nested true/false cases as cond?
  - [ ] print with
  - [x] raise
  - [x] call Erlang correctly e.g. `:erlang.error` (now is `erlang.error`) (reuse code from Elixir Type)
  - [x] format Elixir atoms and boolean correctly (reuse code from ElixirType)

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
  - [x] block
  - [ ] support guards

  - if expression / not used by Elixir (Elixir uses case in abstract code)
  - record / not used by Elixir, probably can be skipped
  - catch / not produced by Elixir, I think
  """

  alias Gradient.ElixirFmt

  @type expr :: :erl_parse.abstract_expr()
  @type clause :: :erl_parse.abstract_clause()

  @doc """
  Convert abstract expressions to Elixir code and format output with formatter.
  """
  @spec pp_expr_format([expr()], keyword()) :: iodata()
  def pp_expr_format(exprs, fmt_opts \\ []) do
    exprs
    |> pretty_print()
    |> Code.format_string!(fmt_opts)
  end

  @doc """
  Convert abstract expressions to Elixir code.
  """
  @spec pretty_print(expr() | [expr()]) :: String.t()
  def pretty_print(exprs) when is_list(exprs) do
    exprs
    |> Enum.map(&pretty_print/1)
    |> Enum.join("; ")
  end

  def pretty_print({:atom, _, val}) when val in [nil, true, false] do
    Atom.to_string(val)
  end

  def pretty_print({:atom, _, val}) do
    case Atom.to_string(val) do
      "Elixir." <> mod -> mod
      str -> ":" <> str
    end
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
    "\'" <> List.to_string(charlist) <> "\'"
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

  def pretty_print({:call, _, {:remote, _, {:atom, _, :erlang}, {:atom, _, :throw}}, [arg]}) do
    "throw " <> pretty_print(arg)
  end

  def pretty_print({:call, _, {:remote, _, {:atom, _, :erlang}, {:atom, _, :error}}, [arg]}) do
    "raise " <> pp_raise_args(arg)
  end

  def pretty_print({:call, _, name, args}) do
    args =
      Enum.map(args, &pretty_print/1)
      |> Enum.join(" ,")

    pp_name(name) <> "(" <> args <> ")"
  end

  def pretty_print({:map, _, pairs}) do
    case try_get_struct(pairs) do
      {nil, pairs} ->
        pairs = format_map_elements(pairs)
        "%{" <> pairs <> "}"

      {struct_name, pairs} ->
        pairs = format_map_elements(pairs)
        name = pretty_print(struct_name)
        "%" <> name <> "{" <> pairs <> "}"
    end
  end

  def pretty_print({:map, _, map, pairs}) do
    pairs = format_map_elements(pairs)
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
    case Atom.to_string(t) |> String.split("@") |> List.first() do
      "_" -> "_"
      "_" <> name -> name
      name -> name
    end
  end

  def pretty_print({:bin, _, [{:bin_element, _, {:string, _, value}, :default, :default}]}) do
    "\"" <> to_string(value) <> "\""
  end

  def pretty_print({:bin, _, elements}) do
    bin =
      elements
      |> Enum.map(fn e -> pretty_print_bin_element(e) end)
      |> Enum.join(", ")

    "<<" <> bin <> ">>"
  end

  def pretty_print({t, _, expr0, quantifiers}) when t in [:bc, :lc] do
    expr0 = pretty_print(expr0)
    "for #{quantifiers}, do: #{expr0}"
  end

  # Quantifiers
  def pretty_print({type, _, pattern, expr}) when type in [:generate, :b_generate] do
    pretty_print(pattern) <> " <- " <> pretty_print(expr)
  end

  def pretty_print({:case, _, condition, clauses} = case_expr) do
    case get_conditional_type(clauses) do
      :if ->
        clauses = pp_clauses(clauses, :if)
        "if " <> pretty_print(condition) <> " do " <> clauses <> " end"

      :cond ->
        "cond do " <> pp_cond_expr(case_expr) <> " end"

      :case ->
        clauses = pp_clauses(clauses, :case)
        "case " <> pretty_print(condition) <> " do " <> clauses <> " end"
    end
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

  def pretty_print({:block, _, body}) do
    pretty_print(body)
  end

  # def pretty_print(expr) do
  # :erl_pp.expr(expr)
  # |> :erlang.iolist_to_binary()
  # end

  @doc """
  Convert abstract clauses to Elixir code
  """
  @spec pp_clauses([clause()], :case | :if | :catch) :: String.t()
  def pp_clauses(clauses, type \\ :case)

  def pp_clauses(clauses, :case) do
    Enum.map(clauses, &pp_case_clause/1) |> Enum.join("; ")
  end

  def pp_clauses(clauses, :if) do
    clauses
    |> Enum.sort_by(fn c -> elem(hd(elem(c, 2)), 2) end, &>=/2)
    |> Enum.map(&pp_if_clause/1)
    |> Enum.join(" else ")
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

  defp pp_if_clause({:clause, _, _, [], body}) do
    pretty_print(body)
  end

  def pp_cond_expr({:case, _, condition, clauses}) do
    clauses = Enum.map(clauses, &cond_clause_pp/1) |> Enum.filter(&(&1 != "")) |> Enum.join("; ")
    pretty_print(condition) <> " -> " <> clauses
  end

  def pp_cond_expr(_), do: ""

  def cond_clause_pp({:clause, _, [{:atom, _, true}], _, body}), do: pretty_print(body)

  def cond_clause_pp({:clause, _, [{:atom, _, false}], _, [case_expr]}),
    do: pp_cond_expr(case_expr)

  def cond_clause_pp(_), do: ""

  def get_conditional_type(clauses) do
    if length(clauses) == 2 and
         Enum.all?(clauses, fn
           {:clause, _, [{:atom, _, bool}], [], _} -> is_boolean(bool)
           _ -> false
         end) do
      if is_cond?(clauses), do: :cond, else: :if
    else
      :case
    end
  end

  def is_cond?(clauses) do
    case Enum.find(clauses, fn {:clause, _, [{:atom, _, bool}], [], _} -> bool == false end) do
      {:clause, _, _, _, [expr]} -> elem(expr, 0) == :case
      _ -> false
    end
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
    value = bin_pp_value(value)

    bin_set_tsl(tsl)
    |> bin_set_size(size)
    |> bin_set_value(value)
  end

  defp bin_pp_value({:string, _, val}), do: "\"" <> List.to_string(val) <> "\""
  defp bin_pp_value(val), do: pretty_print(val)

  defp bin_set_value("", value), do: value
  defp bin_set_value(sufix, value), do: value <> "::" <> sufix

  defp bin_set_size("", :default), do: ""
  defp bin_set_size("", {:integer, _, size}), do: Integer.to_string(size)
  defp bin_set_size(tsl, :default), do: tsl
  defp bin_set_size(tsl, {:integer, _, size}), do: "#{tsl}-size(#{Integer.to_string(size)})"

  defp bin_set_tsl(:default), do: ""
  defp bin_set_tsl([:integer]), do: ""
  defp bin_set_tsl([tsl]), do: Atom.to_string(tsl)
  defp bin_set_tsl(tsl), do: Atom.to_string(tsl)

  def format_map_elements(elems) do
    atom_keys = all_keys_atoms?(elems)
    Enum.map(elems, fn p -> format_map_element(p, atom_keys) end) |> Enum.join(", ")
  end

  @spec format_map_element(tuple(), boolean()) :: String.t()
  def format_map_element({_field, _, key, value}, shortand_syntax) do
    value = pretty_print(value)

    if shortand_syntax do
      {:atom, _, key} = key
      Atom.to_string(key) <> ": " <> value
    else
      pretty_print(key) <> " => " <> value
    end
  end

  def all_keys_atoms?(pairs) do
    Enum.all?(pairs, fn {_, _, key, _} -> :atom == elem(key, 0) end)
  end

  @spec try_get_struct([tuple()]) :: {struct_name :: nil | expr(), pairs_left :: [tuple()]}
  def try_get_struct(pairs) do
    {n, ps} =
      Enum.reduce(pairs, {nil, []}, fn p, {n, ps} ->
        case get_struct_name(p) do
          nil -> {n, [p | ps]}
          name -> {name, ps}
        end
      end)

    {n, Enum.reverse(ps)}
  end

  def get_struct_name({_, _, {:atom, _, :__struct__}, val}), do: val
  def get_struct_name(_), do: nil

  @spec cons_to_int_list(tuple()) :: {:ok, [integer()]} | :error
  def cons_to_int_list(cons) do
    try do
      {:ok, try_int_list_(cons)}
    catch
      nil ->
        :error
    end
  end

  defp pp_raise_args(
         {:call, _, {:remote, _, {:atom, _, RuntimeError}, {:atom, _, :exception}}, [arg]}
       ) do
    pretty_print(arg)
  end

  defp pp_raise_args({:call, _, {:remote, _, error_type, {:atom, _, :exception}}, [arg]}) do
    pretty_print(error_type) <> ", " <> pretty_print(arg)
  end

  defp pp_raise_args(arg) do
    pretty_print(arg)
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
