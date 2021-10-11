defmodule Gradient.ElixirFmt do
  @moduledoc """
  Module that handles formatting and printing error messages produced by Gradient in Elixir.
  """
  @behaviour Gradient.Fmt

  alias :gradualizer_fmt, as: FmtLib
  alias GradualizerEx.ElixirType

  def print_errors(errors, opts) do
    for {file, e} <- errors do
      opts = Keyword.put(opts, :filename, file)
      print_error(e, opts)
    end
  end

  def print_error(error, opts) do
    file = Keyword.get(opts, :filename)
    fmt_loc = Keyword.get(opts, :fmt_location, :verbose)
    opts = Keyword.put(opts, :fmt_type_fun, &ElixirType.pretty_print/1)

    case file do
      nil -> :ok
      _ when fmt_loc == :brief -> :io.format("~s:", [file])
      _ -> :io.format("~s: ", [file])
    end

    :io.put_chars(format_type_error(error, opts))
  end

  @impl Gradient.Fmt
  def format_type_error({:type_error, expression, actual_type, expected_type}, opts)
      when is_tuple(expression) do
    format_expr_type_error(expression, actual_type, expected_type, opts)
  end

  def format_type_error(error, opts) do
    :gradualizer_fmt.format_type_error(error, opts) ++ '\n'
  end

  def format_expr_type_error(expression, actual_type, expected_type, opts) do
    {inline_expr, fancy_expr} =
      case try_highlight_in_context(expression, opts) do
        {:error, _e} -> {" " <> pp_expr(expression, opts), ""}
        {:ok, fancy} -> {"", fancy}
      end

    :io_lib.format(
      "~sThe ~s~ts~s is expected to have type ~ts but it has type ~ts~n~ts~n~n",
      [
        format_location(expression, :brief, opts),
        describe_expr(expression),
        inline_expr,
        format_location(expression, :verbose, opts),
        pp_type(expected_type, opts),
        pp_type(actual_type, opts),
        fancy_expr
      ]
    )
  end

  def format_location(expression, fmt_type, opts \\ []) do
    case Keyword.get(opts, :fmt_location, :verbose) do
      ^fmt_type -> FmtLib.format_location(expression, fmt_type)
      :verbose -> ""
    end
  end

  def pp_expr(expression, _opts) do
    IO.ANSI.blue() <> "#{inspect(expression)}" <> IO.ANSI.reset()
  end

  def pp_type(type, _opts) do
    pp = ElixirType.pretty_print(type)
    IO.ANSI.cyan() <> pp <> IO.ANSI.reset()
  end

  def try_highlight_in_context(expression, opts) do
    forms = Keyword.get(opts, :forms)

    with :ok <- has_location?(expression),
         {:ok, path} <- get_ex_file_path(forms),
         {:ok, code} <- File.read(path) do
      code_lines = String.split(code, ~r/\R/)
      {:ok, highlight_in_context(expression, code_lines)}
    end
  end

  def has_location?(expression) do
    if elem(expression, 1) == 0 do
      {:error, "The location is missing in the expression"}
    else
      :ok
    end
  end

  @spec highlight_in_context(tuple(), [String.t()]) :: String.t()
  def highlight_in_context(expression, context) do
    line = elem(expression, 1)

    context
    |> Enum.with_index(1)
    |> filter_context(line, 2)
    |> underscore_line(line)
    |> Enum.join("\n")
  end

  def filter_context(lines, loc, ctx_size \\ 1) do
    line = :erl_anno.line(loc)
    range = (line - ctx_size)..(line + ctx_size)

    Enum.filter(lines, fn {_, number} -> number in range end)
  end

  def underscore_line(lines, line) do
    Enum.map(lines, fn {str, n} ->
      if(n == line) do
        IO.ANSI.underline() <> IO.ANSI.red() <> to_string(n) <> " " <> str <> IO.ANSI.reset()
      else
        to_string(n) <> " " <> str
      end
    end)
  end

  def get_ex_file_path([{:attribute, 1, :file, {path, 1}} | _]), do: {:ok, path}
  def get_ex_file_path(_), do: {:error, :not_found}

  # defp warning_error_not_handled(error) do
  # msg = "\nElixir formatter not exist for #{inspect(error, pretty: true)} using default \n"
  # String.to_charlist(IO.ANSI.light_yellow() <> msg <> IO.ANSI.reset())
  # end

  @spec describe_expr(:gradualizer_type.abstract_expr()) :: binary()
  def describe_expr({:atom, _, _}), do: "atom"
  def describe_expr({:bc, _, _, _}), do: "binary comprehension"
  def describe_expr({:bin, _, _}), do: "bit expression"
  def describe_expr({:block, _, _}), do: "block"
  def describe_expr({:char, _, _}), do: "character"
  def describe_expr({:call, _, _, _}), do: "function call"
  def describe_expr({:catch, _, _}), do: "catch expression"
  def describe_expr({:case, _, _, _}), do: "case expression"
  def describe_expr({:cons, _, _, _}), do: "list"
  def describe_expr({:float, _, _}), do: "float"
  def describe_expr({:fun, _, _}), do: "fun expression"
  def describe_expr({:integer, _, _}), do: "integer"
  def describe_expr({:if, _, _}), do: "if expression"
  def describe_expr({:lc, _, _, _}), do: "list comprehension"
  def describe_expr({:map, _, _}), do: "map"
  def describe_expr({:map, _, _, _}), do: "map update"
  def describe_expr({:match, _, _, _}), do: "match"
  def describe_expr({:named_fun, _, _, _}), do: "named fun expression"
  def describe_expr({nil, _}), do: "empty list"
  def describe_expr({:op, _, 'not', _}), do: "negation"
  def describe_expr({:op, _, '-', _}), do: "negation"
  def describe_expr({:op, _, op, _, _}), do: to_string(:io_lib.format("~w expression", [op]))
  def describe_expr({:record, _, _, _}), do: "record"
  def describe_expr({:receive, _, _, _, _}), do: "receive expression"
  def describe_expr({:record, _, _, _, _}), do: "record update"
  def describe_expr({:record_field, _, _, _, _}), do: "record field"
  def describe_expr({:record_index, _, _, _}), do: "record index"
  def describe_expr({:string, _, _}), do: "string"
  def describe_expr({:tuple, _, _}), do: "tuple"
  def describe_expr({:try, _, _, _, _, _}), do: "try expression"
  def describe_expr({:var, _, _}), do: "variable"
  def describe_expr(_), do: "expression"
end
