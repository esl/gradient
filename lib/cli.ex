defmodule Gradient.CLI do
  require Logger

  @moduledoc """
  Gradient CLI module responsible for
  accepting shell params and starting gradualizer.

  ## Command-line options

    * `--no-compile` - do not compile even if needed
    * `--no-ex-check` - do not perform checks specyfic for Elixir
      (from ElixirChecker module)
    * `--no-gradualizer-check` - do not perform the Gradualizer checks
    * `--no-specify` - do not specify missing lines in AST what can
      result in less precise error messages
    * `--source-path` -  provide a path to the .ex file containing code for analyzed .beam

    * `--no-deps` - do not import dependencies to the Gradualizer
    * `--stop_on_first_error` - stop type checking at the first error
    * `--infer` - infer type information from literals and other language
      constructs,
    * `--verbose` - show what Gradualizer is doing
    * `--no-fancy` - do not use fancy error messages
    * `--fmt-location none` - do not display location for easier comparison
    * `--fmt-location brief` - display location for machine processing
    * `--fmt-location verbose` - display location for human readers (default)

    * `--no-colors` - do not use colors in printed messages
    * `--expr-color ansicode` - set color for expressions (default: cyan)
    * `--type-color ansicode` - set color for types
    * `--underscore-color ansicode` - set color for the underscored invalid code part
      in the fancy messages

    # --path-add - append a list of comma-delimited paths to the Erlang code path
    # --module - add name of the specific module to check in a source file

  Warning! Flags passed to this task are passed on to Gradualizer.
  """

  @options [
    # skip phases options
    no_compile: :boolean,
    no_ex_check: :boolean,
    no_gradualizer_check: :boolean,
    no_specify: :boolean,
    # checker options
    source_path: :string,
    no_deps: :boolean,
    stop_on_first_error: :boolean,
    infer: :boolean,
    verbose: :boolean,
    # formatter options
    no_fancy: :boolean,
    fmt_location: :string,
    # colors options
    no_colors: :boolean,
    expr_color: :string,
    type_color: :string,
    underscore_color: :string,
    # path and compiler options
    path_add: :string,
    module: :string
  ]

  def main(args) do
    {options, user_paths, _invalid} = OptionParser.parse(args, strict: @options)

    options = Enum.reduce(options, [], &prepare_option/2)

    if module_flag_absent_or_provided_with_file_path?(options, user_paths) do
      # Gradualizer has to be stopped, otherwise adding the extra code paths won't take effect.
      # We don't want to worry the user with the stop message, though.
      Logger.configure(level: :warning)
      Application.stop(:gradualizer)
      check_asdf_paths()
      maybe_path_add(options)
      # Start Gradualizer application
      Application.ensure_all_started(:gradualizer)

      # Get paths to files
      files = get_paths(user_paths, options)

      IO.puts("Typechecking files...")

      files
      |> Stream.map(&Gradient.type_check_file(&1, options))
      |> Stream.concat()
      |> execute(options)

      :ok
    else
      IO.puts("Use --module when pointing at a single *.ex file.")
    end
  end

  defp execute(stream, opts) do
    crash_on_error? = Keyword.get(opts, :crash_on_error, false)

    stream
    |> Enum.to_list()
    |> List.flatten()
    |> Enum.reduce_while(0, fn
      stream_result, acc ->
        if not crash_on_error? do
          stream_result
          |> case do
            :ok ->
              {:cont, acc}

            {:error, errors, _} ->
              total_errors = errors |> Enum.count() |> Kernel.+(acc)
              {:cont, total_errors}
          end
        else
          {:halt, 1}
        end
    end)
    |> case do
      0 ->
        IO.puts([
          IO.ANSI.bright(),
          IO.ANSI.green(),
          "No errors found!",
          IO.ANSI.reset()
        ])

      count ->
        IO.puts([
          IO.ANSI.bright(),
          IO.ANSI.red(),
          "Total errors: #{count}",
          IO.ANSI.reset()
        ])

        system_halt_fn().(1)
    end
  end

  defp system_halt_fn do
    Application.get_env(:gradient, :__system_halt__, &System.halt/1)
  end

  defp maybe_path_add(options) do
    if options[:path_add] do
      options[:path_add]
      |> String.split(",")
      |> Enum.map(fn path ->
        path
        |> Path.expand()
        |> to_charlist()
      end)
      |> :code.add_paths()
    end
  end

  defp prepare_color_option(opts, pair) do
    Keyword.update(opts, :ex_colors, [pair], fn color_opts ->
      [pair | color_opts]
    end)
  end

  defp prepare_option({:expr_color, color}, opts),
    do: prepare_color_option(opts, {:expression, String.to_atom(color)})

  defp prepare_option({:type_color, color}, opts),
    do: prepare_color_option(opts, {:type, String.to_atom(color)})

  defp prepare_option({:underscore_color, color}, opts),
    do: prepare_color_option(opts, {:underscored_line, String.to_atom(color)})

  defp prepare_option({:no_colors, _}, opts), do: prepare_color_option(opts, {:use_colors, false})

  defp prepare_option({:fmt_location, v}, opts), do: [{:fmt_location, String.to_atom(v)} | opts]

  defp prepare_option({:no_fancy, _}, opts), do: [{:fancy, false} | opts]

  defp prepare_option({:stop_on_first_error, _}, opts), do: [{:crash_on_error, true} | opts]

  defp prepare_option({k, v}, opts), do: [{k, v} | opts]

  defp get_paths([], _options), do: get_paths_from_dir([File.cwd!()])

  defp get_paths(paths, _options), do: get_paths_from_dir(paths)

  defp get_paths_from_dir(paths) do
    paths
    |> Enum.flat_map(fn p ->
      if File.dir?(p) do
        expanded_path = Path.expand(p)
        Path.wildcard(Path.join([expanded_path, "/**/*.ex"]))
      else
        [p]
      end
    end)
  end

  defp module_flag_absent_or_provided_with_file_path?(options, user_paths) do
    module_flag = Keyword.get(options, :module, nil)

    cond do
      is_binary(module_flag) && Enum.count(user_paths) == 1 &&
          String.ends_with?(List.first(user_paths), ".ex") ->
        true

      is_nil(module_flag) ->
        true

      true ->
        false
    end
  end

  defp check_asdf_paths() do
    try do
      {elixir_bin, 0} = System.cmd("asdf", ["which", "elixir"])

      Path.wildcard(elixir_bin |> Path.dirname() |> Path.dirname() |> Path.join("lib/*/ebin"))
      |> Enum.map(fn path ->
        path
        |> Path.expand()
        |> to_charlist()
      end)
      |> :code.add_paths()
    rescue
      ASDFError ->
        IO.puts("Elixir is not managed by ASDF, #{inspect(ASDFError)}")
    end
  end
end
