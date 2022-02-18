defmodule Gradient.ElixirExpr do
  @moduledoc """
  Convert the Erlang abstract expressions to the Elixir code.
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
    |> pp_expr()
    |> Code.format_string!(fmt_opts)
  end

  @doc """
  Convert abstract expressions to Elixir code.
  """
  @spec pp_expr(expr() | [expr()]) :: String.t()
  def pp_expr(exprs) when is_list(exprs) do
    exprs
    |> Enum.map(&pp_expr/1)
    |> Enum.join("; ")
  end

  def pp_expr({:atom, _, val}) when val in [nil, true, false] do
    Atom.to_string(val)
  end

  def pp_expr({:atom, _, val}) do
    case Atom.to_string(val) do
      "Elixir." <> mod -> mod
      str -> ":\"" <> str <> "\""
    end
  end

  def pp_expr({:char, _, l}) do
    "?" <> List.to_string([l])
  end

  def pp_expr({:float, _, l}) do
    Float.to_string(l)
  end

  def pp_expr({:integer, _, l}) do
    Integer.to_string(l)
  end

  def pp_expr({:string, _, charlist}) do
    "\'" <> List.to_string(charlist) <> "\'"
  end

  def pp_expr({:cons, _, _, _} = cons) do
    case cons_to_int_list(cons) do
      {:ok, l} ->
        inspect(l)

      :error ->
        items = pp_cons(cons)

        "[" <> items <> "]"
    end
  end

  def pp_expr({:fun, _, {:function, name, arity}}) do
    "&#{name}/#{arity}"
  end

  def pp_expr({:fun, _, {:function, {:atom, _, module}, {:atom, _, name}, arity}}) do
    module = ElixirFmt.parse_module(module)
    name = Atom.to_string(name)
    arity = pp_expr(arity)
    "&#{module}#{name}/#{arity}"
  end

  def pp_expr({:fun, _, {:clauses, clauses}}) do
    # print all as a one line
    clauses = pp_clauses(clauses)
    "fn " <> clauses <> " end"
  end

  def pp_expr({:call, _, {:remote, _, {:atom, _, :erlang}, {:atom, _, :throw}}, [arg]}) do
    "throw " <> pp_expr(arg)
  end

  def pp_expr(
        {:call, _, {:remote, _, {:atom, _, :erlang}, {:atom, _, :error}},
         [
           {:call, _, {:remote, _, {:atom, _, :erlang}, {:atom, _, :raise}},
            [
              {:atom, _, :error},
              {:call, _, {:remote, _, {:atom, _, Kernel.Utils}, {:atom, _, :raise}}, [var]},
              var_stacktrace
            ]}
         ]}
      ) do
    "reraise " <> pp_expr(var) <> ", " <> pp_expr(var_stacktrace)
  end

  def pp_expr({:call, _, {:remote, _, {:atom, _, :erlang}, {:atom, _, :error}}, [arg]}) do
    "raise " <> pp_raise_arg(arg)
  end

  def pp_expr({:call, _, name, args}) do
    args =
      Enum.map(args, &pp_expr/1)
      |> Enum.join(", ")

    pp_name(name) <> "(" <> args <> ")"
  end

  def pp_expr({:map, _, pairs}) do
    case try_get_struct(pairs) do
      {nil, pairs} ->
        pairs = format_map_elements(pairs)
        "%{" <> pairs <> "}"

      {struct_name, pairs} ->
        pairs = format_map_elements(pairs)
        name = pp_expr(struct_name)
        "%" <> name <> "{" <> pairs <> "}"
    end
  end

  def pp_expr({:map, _, map, pairs}) do
    pairs = format_map_elements(pairs)
    map = pp_expr(map)
    "%{" <> map <> " | " <> pairs <> "}"
  end

  def pp_expr({:match, _, var, expr}) do
    pp_expr(var) <> " = " <> pp_expr(expr)
  end

  def pp_expr({nil, _}) do
    "[]"
  end

  def pp_expr({:op, _, op, type}) do
    operator_to_string(op) <> " " <> pp_expr(type)
  end

  def pp_expr({:op, _, op, left_type, right_type}) do
    operator = " " <> operator_to_string(op) <> " "
    pp_expr(left_type) <> operator <> pp_expr(right_type)
  end

  def pp_expr({:tuple, _, elements}) do
    elements_str = Enum.map(elements, &pp_expr(&1)) |> Enum.join(", ")
    "{" <> elements_str <> "}"
  end

  def pp_expr({:var, anno, t}) do
    case Atom.to_string(t) |> String.split("@") |> List.first() do
      "_" -> if :erl_anno.generated(anno), do: "_gen", else: "_"
      "_" <> name -> name
      name -> name
    end
  end

  def pp_expr({:bin, _, [{:bin_element, _, {:string, _, value}, :default, :default}]}) do
    "\"" <> to_string(value) <> "\""
  end

  def pp_expr({:bin, _, elements}) do
    bin =
      elements
      |> Enum.map(fn e -> pp_bin_element(e) end)
      |> Enum.join(", ")

    "<<" <> bin <> ">>"
  end

  def pp_expr({t, _, expr0, quantifiers}) when t in [:bc, :lc] do
    expr0 = pp_expr(expr0)
    pquantifiers = pp_expr(quantifiers)
    "for #{pquantifiers}, do: #{expr0}"
  end

  # Quantifiers
  def pp_expr({:b_generate, _, pattern, expr}) do
    # drop >> to insert quantifier before
    ppatern = String.slice(pp_expr(pattern), 0..-3)
    # add a space before >> for a case when expr is a bin
    ppatern <> " <- " <> pp_expr(expr) <> " >>"
  end

  def pp_expr({:case, _, condition, clauses} = case_expr) do
    case get_conditional_type(clauses) do
      :if ->
        clauses = pp_clauses(clauses, :if)
        "if " <> pp_expr(condition) <> " do " <> clauses <> " end"

      :cond ->
        "cond do " <> pp_cond_expr(case_expr) <> " end"

      :case ->
        clauses = pp_clauses(clauses, :case)
        "case " <> pp_expr(condition) <> " do " <> clauses <> " end"
    end
  end

  def pp_expr({:receive, _, clauses}) do
    "receive do " <> pp_clauses(clauses) <> " end"
  end

  def pp_expr({:receive, _, clauses, after_value, after_body}) do
    pclauses = pp_clauses(clauses)
    pvalue = pp_expr(after_value)
    pafter_body = pp_expr(after_body)
    "receive do " <> pclauses <> " after " <> pvalue <> " -> " <> pafter_body <> " end"
  end

  def pp_expr({:try, _, body, else_block, catchers, after_block}) do
    "try do "
    |> append_try_body(body)
    |> maybe_try_else(else_block)
    |> maybe_try_catch(catchers)
    |> maybe_try_after(after_block)
    |> Kernel.<>(" end")
  end

  def pp_expr({:block, _, body}) do
    pp_expr(body)
  end

  # def pp_expr(expr) do
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

  def pp_guards([[guard]]) do
    " when " <> pp_expr(guard)
  end

  # Private

  def operator_to_string(:andalso), do: operator_to_string(:and)
  def operator_to_string(:orelse), do: operator_to_string(:or)
  def operator_to_string(op), do: Atom.to_string(op)

  defp pp_catch_clause({:clause, _, [{:tuple, _, [type, var, _stacktrace]}], guards, body}) do
    # rescue/catch clause
    case {elem(type, 2), get_error_struct(guards)} do
      {:error, {:ok, error_struct}} ->
        # rescue when error is struct
        {var2, body2} = get_error_var(var, body)

        pp_expr(type) <>
          ", %" <>
          pp_expr(error_struct) <>
          "{} = " <> pp_expr(var2) <> " -> " <> pp_expr(body2)

      {:error, :not_found} ->
        # rescue
        {var2, body2} = get_error_var(var, body)

        pp_expr(type) <>
          ", " <> pp_expr(var2) <> " -> " <> pp_expr(body2)

      {:throw, :not_found} ->
        # throw
        pp_expr(type) <> ", " <> pp_expr(var) <> " -> " <> pp_expr(body)
    end
  end

  defp pp_case_clause({:clause, _, patterns, guards, body}) do
    patterns =
      patterns
      |> Enum.map(&pp_expr/1)
      |> Enum.join(", ")

    patterns <> pp_guards(guards) <> " -> " <> pp_expr(body)
  end

  defp pp_if_clause({:clause, _, _, [], body}) do
    pp_expr(body)
  end

  def pp_cond_expr({:case, _, condition, clauses}) do
    clauses = Enum.map(clauses, &cond_clause_pp/1) |> Enum.filter(&(&1 != "")) |> Enum.join("; ")
    pp_expr(condition) <> " -> " <> clauses
  end

  def pp_cond_expr(_), do: ""

  def cond_clause_pp({:clause, _, [{:atom, _, true}], _, body}), do: pp_expr(body)

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
    res <> pp_expr(body)
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
    res <> "; after " <> pp_expr(else_block)
  end

  def get_error_struct([[{:op, _, :andalso, {:op, _, :==, _, error_struct}, _}]]) do
    {:ok, error_struct}
  end

  def get_error_struct(_) do
    :not_found
  end

  def get_error_var({:var, _, v}, [{:match, _, user_var, {:var, _, v}} | body_tail]) do
    {user_var, body_tail}
  end

  def get_error_var({:var, _, v}, [
        {:match, _, user_var, {:call, _, _, [_, {:var, _, v} | _]}} | body_tail
      ]) do
    # Extract variable from Exception.normalize (used in reraise)
    {user_var, body_tail}
  end

  def get_error_var(var, body) do
    {var, body}
  end

  defp pp_bin_element({:bin_element, _, value, size, tsl}) do
    value = bin_pp_value(value)

    bin_set_tsl(tsl)
    |> bin_set_size(size)
    |> bin_set_value(value)
  end

  defp bin_pp_value({:string, _, val}), do: "\"" <> List.to_string(val) <> "\""
  defp bin_pp_value(val), do: pp_expr(val)

  defp bin_set_value("", value), do: value
  defp bin_set_value(sufix, value), do: value <> "::" <> sufix

  defp bin_set_size("", :default), do: ""
  defp bin_set_size("", {:integer, _, size}), do: Integer.to_string(size)
  defp bin_set_size(tsl, :default), do: tsl
  defp bin_set_size(tsl, {:integer, _, size}), do: "#{tsl}-size(#{Integer.to_string(size)})"

  defp bin_set_tsl(:default), do: ""
  defp bin_set_tsl([:integer]), do: ""
  defp bin_set_tsl([tsl]), do: Atom.to_string(tsl)

  def format_map_elements(elems) do
    atom_keys = all_keys_atoms?(elems)
    Enum.map(elems, fn p -> format_map_element(p, atom_keys) end) |> Enum.join(", ")
  end

  @spec format_map_element(tuple(), boolean()) :: String.t()
  def format_map_element({_field, _, key, value}, shortand_syntax) do
    value = pp_expr(value)

    if shortand_syntax do
      {:atom, _, key} = key
      "\"" <> Atom.to_string(key) <> "\": " <> value
    else
      pp_expr(key) <> " => " <> value
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

  defp pp_raise_arg({:call, _, {:remote, _, error_type, {:atom, _, :exception}}, [{nil, _}]}) do
    pp_expr(error_type)
  end

  defp pp_raise_arg(
         {:call, _, {:remote, _, {:atom, _, RuntimeError}, {:atom, _, :exception}}, [arg]}
       ) do
    pp_expr(arg)
  end

  defp pp_raise_arg({:call, _, {:remote, _, error_type, {:atom, _, :exception}}, [arg]}) do
    pp_expr(error_type) <> ", " <> pp_expr(arg)
  end

  defp pp_raise_arg(arg) do
    pp_expr(arg)
  end

  defp try_int_list_({nil, _}), do: []
  defp try_int_list_({:cons, _, {:integer, _, val}, t}), do: [val | try_int_list_(t)]
  defp try_int_list_(_), do: throw(nil)

  defp pp_cons({:cons, _, h, {nil, _}}), do: pp_expr(h)
  defp pp_cons({:cons, _, h, {:var, _, _} = v}), do: pp_expr(h) <> " | " <> pp_expr(v)
  defp pp_cons({:cons, _, h, t}), do: pp_expr(h) <> ", " <> pp_cons(t)

  defp pp_name({:remote, _, {:atom, _, m}, {:atom, _, n}}),
    do: ElixirFmt.parse_module(m) <> to_string(n)

  defp pp_name({:atom, _, n}), do: to_string(n)
end
