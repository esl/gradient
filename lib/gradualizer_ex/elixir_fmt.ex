defmodule GradualizerEx.ElixirFmt do
  @moduledoc """
  Module that handles formatting and printing error messages produced by Gradualizer in Elixir.
  """
  @behaviour GradualizerEx.Fmt

  alias :gradualizer_fmt, as: FmtLib

  @impl GradualizerEx.Fmt
  def format_type_error({:type_error, expression, actual_type, expected_type}, opts)
      when is_tuple(expression) do
    format_expr_type_error(expression, actual_type, expected_type, opts)
  end

  def format_type_error(error, opts) do
    warning_msg = warning_error_not_handled(error)
    formatted = :gradualizer_fmt.format_type_error(error, opts)

    warning_msg ++ formatted
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
        FmtLib.describe_expr(expression),
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

  def pp_type(expression, _opts) do
    pp = expression |> :typelib.pp_type() |> to_string()
    IO.ANSI.yellow() <> pp <> IO.ANSI.reset()
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

  def filter_context(lines, line, ctx_size \\ 1) do
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

  defp warning_error_not_handled(error) do
    msg = "\nElixir formatter not exist for #{inspect(error, pretty: true)} using default \n"
    String.to_charlist(IO.ANSI.light_yellow() <> msg <> IO.ANSI.reset())
  end
end
