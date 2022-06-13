defmodule Gradient.ElixirFmt do
  @moduledoc """
  Module that handles formatting and printing error messages produced by Gradualizer in Elixir.

  Options:
  - `ex_colors`: list of color options:
    - {`use_colors`, boolean()}: - wheather to use the colors, default: true
    - {`expression`, ansicode()}: color of the expressions, default: :yellow
    - {`type`, ansicode()}: color of the types, default: :cyan
    - {`underscored_line`, ansicode()}: color of the underscored line pointed the error in code, default: :red

  - `ex_fmt_expr_fun`: function to pretty print an expression AST in Elixir `(abstract_expr()) -> iodata()`.

  - `ex_fmt_type_fun`: function to pretty print an type AST in Elixir `(abstract_type() -> iodata())`.

  - `{fancy, boolean()}`: do not use fancy error messages, default: true

  - Gradualizer options, but some of them are overwritten by Gradient.
  """
  @behaviour Gradient.Fmt

  alias :gradualizer_fmt, as: FmtLib
  alias Gradient.ElixirType
  alias Gradient.ElixirExpr
  alias Gradient.Types

  @type colors_opts() :: [
          use_colors: boolean(),
          expression: IO.ANSI.ansicode(),
          type: IO.ANSI.ansicode(),
          underscored_line: IO.ANSI.ansicode()
        ]
  @type options() :: [
          ex_colors: colors_opts(),
          ex_fmt_type_fun: (Types.abstract_type() -> iodata()),
          ex_fmt_expr_fun: (Types.abstract_expr() -> iodata())
        ]

  @default_colors [use_colors: true, expression: :yellow, type: :cyan, underscored_line: :red]

  def print_errors(errors, opts) do
    for {file, e} <- errors do
      opts = Keyword.put(opts, :filename, file)
      print_error(e, opts)
    end
  end

  def print_error(error, opts) do
    file = Keyword.get(opts, :filename)
    fmt_loc = Keyword.get(opts, :fmt_location, :verbose)

    case file do
      nil -> :ok
      _ when fmt_loc == :brief -> :io.format("~s:", [file])
      _ -> :io.format("~s: ", [file])
    end

    :io.put_chars(format_error(error, opts))
  end

  def format_error(error, opts) do
    opts = Keyword.put_new(opts, :color, false)
    opts = Keyword.put_new(opts, :fmt_type_fun, pp_type_fun(opts))
    opts = Keyword.put_new(opts, :fmt_expr_fun, pp_expr_fun(opts))
    format_type_error(error, opts)
  end

  @impl Gradient.Fmt
  def format_type_error({:type_error, expression, actual_type, expected_type}, opts)
      when is_tuple(expression) do
    case expression do
      {:call, _, {:atom, _, assert_or_annotate}, [inner_expr, _]}
      when assert_or_annotate in [:"::", :":::"] ->
        format_expr_type_error(inner_expr, actual_type, expected_type, opts)

      _ ->
        format_expr_type_error(expression, actual_type, expected_type, opts)
    end
  end

  def format_type_error({:nonexhaustive, anno, example}, opts) do
    formatted_example =
      case example do
        [x | xs] ->
          :lists.foldl(
            fn a, acc ->
              [pp_expr(a, opts), "\n\t" | acc]
            end,
            [pp_expr(x, opts)],
            xs
          )
          |> Enum.reverse()

        x ->
          pp_expr(x, opts)
      end

    :io_lib.format(
      "~sNonexhaustive patterns~s~s",
      [
        format_location(anno, :brief, opts),
        format_location(anno, :verbose, opts),
        case :proplists.get_value(:fmt_location, opts, :verbose) do
          :brief ->
            :io_lib.format(": ~s\n", formatted_example)

          :verbose ->
            :io_lib.format("\nExample values which are not covered:~n\t~s~n", [formatted_example])
        end
      ]
    )
  end

  def format_type_error(
        {:spec_error, :wrong_spec_name, anno, name, arity},
        opts
      ) do
    :io_lib.format(
      "~sThe spec ~p/~p~s doesn't match the function name/arity~n",
      [
        format_location(anno, :brief, opts),
        name,
        arity,
        format_location(anno, :verbose, opts)
      ]
    )
  end

  def format_type_error({:spec_error, :mixed_specs, anno, name, arity}, opts) do
    :io_lib.format(
      "~sThe spec ~p/~p~s follows a spec with different name/arity~n",
      [
        format_location(anno, :brief, opts),
        name,
        arity,
        format_location(anno, :verbose, opts)
      ]
    )
  end

  def format_type_error({:call_undef, anno, module, func, arity}, opts) do
    :io_lib.format(
      "~sCall to undefined function ~s~p/~p~s~n",
      [
        format_location(anno, :brief, opts),
        parse_module(module),
        func,
        arity,
        format_location(anno, :verbose, opts)
      ]
    )
  end

  def format_type_error({:undef, :record, anno, {module, recName}}, opts) do
    :io_lib.format(
      "~sUndefined record ~p:~p~s~n",
      [
        format_location(anno, :brief, opts),
        module,
        recName,
        format_location(anno, :verbose, opts)
      ]
    )
  end

  def format_type_error({:undef, :record, anno, recName}, opts) do
    :io_lib.format(
      "~sUndefined record ~p~s~n",
      [format_location(anno, :brief, opts), recName, format_location(anno, :verbose, opts)]
    )
  end

  def format_type_error({:undef, :record_field, fieldName}, opts) do
    :io_lib.format(
      "~sUndefined record field ~s~s~n",
      [
        format_location(fieldName, :brief, opts),
        pp_expr(fieldName, opts),
        format_location(fieldName, :verbose, opts)
      ]
    )
  end

  def format_type_error({:undef, :user_type, anno, {name, arity}}, opts) do
    :io_lib.format(
      "~sUndefined type ~p/~p~s~n",
      [format_location(anno, :brief, opts), name, arity, format_location(anno, :verbose, opts)]
    )
  end

  def format_type_error({:undef, type, anno, {module, name, arity}}, opts)
      when type in [:user_type, :remote_type] do
    type =
      case type do
        :user_type -> "type"
        :remote_type -> "remote type"
      end

    module = "#{inspect(module)}"

    :io_lib.format(
      "~sUndefined ~s ~s.~p/~p~s~n",
      [
        format_location(anno, :brief, opts),
        type,
        module,
        name,
        arity,
        format_location(anno, :verbose, opts)
      ]
    )
  end

  def format_type_error(error, opts) do
    :gradualizer_fmt.format_type_error(error, opts) ++ '\n'
  end

  def format_expr_type_error(expression, actual_type, expected_type, opts) do
    {inline_expr, fancy_expr} =
      case try_highlight_in_context(expression, opts) do
        {:error, _e} -> {[" " | pp_expr(expression, opts)], ""}
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
      _ -> ""
    end
  end

  def pp_expr_fun(opts) do
    fmt = Keyword.get(opts, :ex_fmt_expr_fun, &ElixirExpr.pp_expr_format/1)
    colors = get_colors_with_default(opts)
    {:ok, use_colors} = Keyword.fetch(colors, :use_colors)
    {:ok, expr_color} = Keyword.fetch(colors, :expression)

    fn expression ->
      IO.ANSI.format([expr_color, fmt.(expression)], use_colors)
    end
  end

  def pp_type_fun(opts) do
    fmt = Keyword.get(opts, :ex_fmt_type_fun, &ElixirType.pp_type_format/1)
    colors = get_colors_with_default(opts)
    {:ok, use_colors} = Keyword.fetch(colors, :use_colors)
    {:ok, type_color} = Keyword.fetch(colors, :type)

    fn type ->
      [IO.ANSI.format([type_color, fmt.(type)], use_colors)]
    end
  end

  def get_colors_with_default(opts) do
    case Keyword.fetch(opts, :ex_colors) do
      {:ok, colors} ->
        colors ++ @default_colors

      _ ->
        @default_colors
    end
  end

  def pp_expr(expression, opts) do
    pp_expr_fun(opts).(expression)
  end

  def pp_type(type, opts) do
    pp_type_fun(opts).(type)
  end

  @spec try_highlight_in_context(Types.abstract_expr(), options()) ::
          {:ok, iodata()} | {:error, term()}
  def try_highlight_in_context(expression, opts) do
    with :ok <- print_fancy?(opts),
         :ok <- has_location?(expression),
         {:ok, path} <- get_ex_file_path(opts[:forms]),
         {:ok, code} <- File.read(path) do
      code_lines = String.split(code, ~r/\R/)
      {:ok, highlight_in_context(expression, code_lines, opts)}
    end
  end

  def print_fancy?(opts) do
    if Keyword.get(opts, :fancy, true) do
      :ok
    else
      {:error, "The fancy mode is turn off"}
    end
  end

  def has_location?(expression) do
    if elem(expression, 1) == 0 do
      {:error, "The location is missing in the expression"}
    else
      :ok
    end
  end

  @spec highlight_in_context(tuple(), [String.t()], options()) :: iodata()
  def highlight_in_context(expression, context, opts) do
    line = elem(expression, 1)

    context
    |> Enum.with_index(1)
    |> filter_context(line, 2)
    |> underscore_line(line, opts)
    |> Enum.join("\n")
  end

  def filter_context(lines, loc, ctx_size \\ 1) do
    line = :erl_anno.line(loc)
    range = (line - ctx_size)..(line + ctx_size)

    Enum.filter(lines, fn {_, number} -> number in range end)
  end

  def underscore_line(lines, line, opts) do
    Enum.map(lines, fn {str, n} ->
      if(n == line) do
        colors = get_colors_with_default(opts)
        {:ok, use_colors} = Keyword.fetch(colors, :use_colors)
        {:ok, color} = Keyword.fetch(colors, :underscored_line)
        line_str = to_string(n) <> " " <> str

        [
          IO.ANSI.underline(),
          IO.ANSI.format_fragment([color, line_str], use_colors),
          IO.ANSI.reset()
        ]
      else
        to_string(n) <> " " <> str
      end
    end)
  end

  def get_ex_file_path([{:attribute, 1, :file, {path, 1}} | _]), do: {:ok, path}
  def get_ex_file_path(_), do: {:error, :not_found}

  @spec parse_module(atom()) :: String.t()
  def parse_module(:elixir), do: ""

  def parse_module(mod) do
    case Atom.to_string(mod) do
      "Elixir." <> mod_str -> mod_str <> "."
      mod -> ":" <> mod <> "."
    end
  end

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
