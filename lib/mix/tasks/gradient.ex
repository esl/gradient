defmodule Mix.Tasks.Gradient do
  @moduledoc ~s"""
  This task compiles the mix project, collects files with dependencies, specifies Erlang AST,
  and type checks the Elixir code. For type checking, Gradualizer is used, but Gradient provides
  its own checker for Elixir-specific cases.

  ## Command-line options

    * `--no-compile` - do not compile even if needed
    * `--no-ex-check` - do not perform checks specific for Elixir
      (from ElixirChecker module)
    * `--no-gradualizer-check` - do not perform the Gradualizer checks
    * `--no-specify` - do not specify missing lines in AST what can
      result in less precise error messages
    * `--source-path` - provide a path to the .ex file containing code for analyzed .beam
    * `--no-tokens` - do not use tokens to increase the precision of typechecking

    * `--no-deps` - do not import dependencies to the Gradualizer
    * `--stop_on_first_error` - stop type checking at the first error
    * `--infer` - infer type information from literals and other language
      constructs,
    * `--verbose` - show what Gradualizer is doing
    * `--print-filenames` - print the name of every file being analyzed (mainly useful for tests)
    * `--no-fancy` - do not use fancy error messages
    * `--fmt-location none` - do not display location for easier comparison
    * `--fmt-location brief` - display location for machine processing
    * `--fmt-location verbose` - display location for human readers (default)

    * `--no-colors` - do not use colors in printed messages
    * `--expr-color ansicode` - set color for expressions (default: cyan)
    * `--type-color ansicode` - set color for types
    * `--underscore-color ansicode` - set color for the underscored invalid code part
      in the fancy messages

  _Warning!_ Flags passed to this task are passed on to Gradualizer.

  To ignore errors, define a `.gradient_ignore.exs` in the project root folder.
  Check `Gradient.Error` `ignore()` type for more details.
  """
  @shortdoc "Runs gradient with default or given options"

  use Mix.Task

  alias Gradient.ElixirFileUtils

  @options [
    # skip phases options
    no_compile: :boolean,
    no_ex_check: :boolean,
    no_gradualizer_check: :boolean,
    no_specify: :boolean,
    # checker options
    source_path: :string,
    no_tokens: :boolean,
    no_deps: :boolean,
    stop_on_first_error: :boolean,
    infer: :boolean,
    verbose: :boolean,
    print_filenames: :boolean,
    # formatter options
    no_fancy: :boolean,
    fmt_location: :string,
    # colors options
    no_colors: :boolean,
    expr_color: :string,
    type_color: :string,
    underscore_color: :string
  ]

  @impl Mix.Task
  def run(args) do
    {options, user_paths, _invalid} = OptionParser.parse(args, strict: @options)

    ignores = fetch_ignores()

    options = Enum.reduce(options, [], &prepare_option/2)

    # Compile the project before the analysis
    maybe_compile_project(options)
    # Load dependencies
    maybe_load_deps(options)
    # Start Gradualizer application
    Application.ensure_all_started(:gradualizer)
    # Get paths to files
    files = get_paths(user_paths) |> filter_enabled_paths()

    if options[:print_filenames] do
      print_filenames(files)
    end

    IO.puts("Typechecking files...")

    files
    |> Stream.map(fn {app_path, paths} ->
      Stream.map(
        paths,
        &Gradient.type_check_file(
          &1,
          [{:app_path, app_path}, {:ignores, ignores} | options]
        )
      )
    end)
    |> Stream.concat()
    |> execute(options)

    :ok
  end

  defp print_filenames(files) do
    IO.puts("Files to check:")

    cwd = File.cwd!() <> "/"
    # Range for slicing off cwd from the beginning of a string
    cwd_range = String.length(cwd)..-1

    Enum.each(files, fn {app, filenames} ->
      # Print app name
      case app do
        "apps/" <> appname -> IO.puts("Files in app #{appname}:")
        # May be nil for non-umbrella apps
        _ -> :noop
      end

      # Print actual filenames
      for filename <- filenames do
        # Convert charlist to string
        filename = to_string(filename)
        # If the filename starts with the cwd, don't print the cwd
        filename =
          if String.starts_with?(filename, cwd),
            do: String.slice(filename, cwd_range),
            else: filename

        IO.puts(filename)
      end
    end)
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

            {:error, errors} ->
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

  defp maybe_compile_project(options) do
    unless options[:no_compile] || false do
      IO.puts("Compiling project...")
      Mix.Tasks.Compile.run([])
    end
  end

  defp maybe_load_deps(options) do
    if options[:no_deps] || false do
      Application.put_env(:gradualizer, :options, autoimport: false)
    else
      :ok = :code.add_paths(get_compile_paths())
      IO.puts("Loading deps...")
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

  defp get_paths([]), do: get_beam_paths()
  defp get_paths(paths), do: %{nil => get_paths_from_dir(paths)}

  defp get_beam_paths() do
    if Mix.Project.umbrella?() do
      get_umbrella_app_beams_paths()
    else
      get_app_beams_paths()
    end
  end

  defp get_paths_from_dir(paths) do
    paths
    |> Enum.map(fn p ->
      if File.dir?(p) do
        Path.wildcard(Path.join([p, "*.ex"]))
      else
        [p]
      end
    end)
    |> Enum.concat()
  end

  defp get_app_beams_paths() do
    %{
      nil =>
        (Mix.Project.app_path() <> "/ebin/**/*.beam")
        |> Path.wildcard()
        |> Enum.map(&String.to_charlist/1)
    }
  end

  defp get_umbrella_app_beams_paths() do
    Mix.Project.apps_paths()
    |> Enum.map(fn {app_name, app_path} ->
      app_name = Atom.to_string(app_name)

      paths =
        (compile_path(app_name) <> "/**/*.beam")
        |> Path.wildcard()
        |> Enum.map(&String.to_charlist/1)

      {app_path, paths}
    end)
    |> Map.new()
  end

  @spec get_compile_paths() :: [charlist()]
  defp get_compile_paths() do
    if Mix.Project.umbrella?() do
      Mix.Project.apps_paths()
      |> Enum.map(fn {app_name, _} -> to_charlist(compile_path(app_name)) end)
    else
      [to_charlist(Mix.Project.compile_path())]
    end
  end

  @spec fetch_ignores() :: [term()]
  defp fetch_ignores() do
    case File.read(".gradient_ignore.exs") do
      {:ok, content} ->
        case Code.eval_string(content) do
          {[_ | _] = ignores, _binding} ->
            ignores

          _ ->
            []
        end

      {:error, _} ->
        []
    end
  end

  defp compile_path(app_name) do
    Mix.Project.build_path() <> "/lib/" <> to_string(app_name) <> "/ebin"
  end

  @spec filter_enabled_paths(map()) :: map()
  def filter_enabled_paths(apps_paths) do
    apps_paths
    |> Enum.map(fn {app_name, app_files} ->
      {app_name, filter_paths_for_app(app_name, app_files)}
    end)
    |> Map.new()
  end

  defp filter_paths_for_app(app_name, app_files) do
    config = gradient_config_for_app(app_name)

    enabled? = Keyword.get(config, :enabled, true)
    file_overrides_enabled? = Keyword.get(config, :file_overrides, enabled?)

    if file_overrides_enabled? do
      magic_comment =
        if enabled?, do: "# gradient:disable-for-file", else: "# gradient:enable-for-file"

      filter_files_with_magic_comment(app_name, app_files, magic_comment, not enabled?)
    else
      if enabled?, do: app_files, else: []
    end
  end

  defp gradient_config_for_app(app) do
    app_config = mix_config_for_app(app)[:gradient] || []

    if Mix.Project.umbrella?() do
      # Merge in config from umbrella app
      umbrella_config = Mix.Project.config()[:gradient] || []
      Keyword.merge(umbrella_config, app_config)
    else
      app_config
    end
  end

  defp path_for_app(nil), do: ""
  defp path_for_app(app_name), do: app_name <> "/"

  defp mix_config_for_app(nil), do: Mix.Project.config()

  defp mix_config_for_app(app) do
    # Read the file looking for a "defmodule" to get the module name of the app's mixfile
    mixfile_module_str =
      File.stream!(path_for_app(app) <> "mix.exs")
      |> Enum.find(&String.starts_with?(&1, "defmodule"))
      |> (fn a -> Regex.run(~r/defmodule ([\w.]+)/, a) end).()
      |> Enum.at(1)

    mixfile_module = String.to_atom("Elixir." <> mixfile_module_str)

    # return the module's config
    mixfile_module.project()
  end

  defp filter_files_with_magic_comment(app_name, beam_files, comment, should_include?) do
    app_path = path_for_app(app_name) |> Path.expand()
    deps_path = Path.expand(mix_config_for_app(app_name)[:deps_path] || "deps")

    Enum.filter(beam_files, fn beam_path ->
      # Given the path to a .beam file, find out the .ex source file path
      ex_path =
        ex_filename_from_beam(beam_path)
        # Turn the relative path into absolute
        |> Path.expand(app_path)

      # Filter out any paths representing code generated by deps
      is_dep = String.starts_with?(ex_path, deps_path)

      # Filter out the files with the magic comment
      has_magic_comment? =
        File.stream!(ex_path)
        |> Enum.any?(fn line -> String.trim(line) == comment end)

      # Negate has_magic_comment? if should_include? is false
      has_magic_comment? =
        if should_include?, do: has_magic_comment?, else: not has_magic_comment?

      has_magic_comment? and not is_dep
    end)
  end

  defp ex_filename_from_beam(beam_path) do
    case ElixirFileUtils.get_forms(beam_path) do
      {:ok, [[{:attribute, _, :file, {filename, _}} | _] | _]} ->
        # Convert the *.beam compiled filename to its corresponding *.ex source file
        # (it's a charlist initially so we pipe it through to_string)
        filename |> to_string()

      error ->
        raise "Error resolving .ex filename from compiled .beam filename #{inspect(beam_path)}: #{inspect(error)}"
    end
  end
end
