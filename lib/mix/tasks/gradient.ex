defmodule Mix.Tasks.Gradient do
  @moduledoc ~s"""
  This task compiles the mix project, collects files with dependencies, specify ast tree,
  and run Elixir checks and Gradualizer.

  ## Command-line options

    * `--no-compile` - do not compile even if needed
    * `--no-ex-check` - do not perform checks specyfic for Elixir
      (from ElixirChecker module)
    * `--no-gradualizer-check` - do not perform Gradualizer checks

    * `--stop_on_first_error` - stop type checking at the first error
    * `--infer` - infer type information from literals and other language
      constructs,
    * `--verbose` - show what Gradient is doing
    * `--no-fancy` - do not use fancy error messages
    * `--fmt-location none` - do not display location for easier comparison
    * `--fmt-location brief` - display location for machine processing 
    * `--fmt-location verbose` - display location for human readers (default)

    * `--no-colors` - do not use colors in printed messages
    * `--expr-color ansicode` - set color for expressions (default: cyan)
    * `--type-color ansicode` - set color for types
    * `--underscore-color ansicode` - set color for the underscored invalid code part
      in the fancy messages

  Warning flags passed to this task are passed on to :gradualizer.
  """
  @shortdoc "Runs gradient with default or project-defined flags"

  use Mix.Task

  @options [
    # skip phases options
    no_compile: :boolean,
    no_ex_check: :boolean,
    no_gradualizer_check: :boolean,
    no_specify: :boolean,
    # checker options
    stop_on_first_error: :boolean,
    infer: :boolean,
    # formatter options
    verbose: :boolean,
    no_fancy: :boolean,
    fmt_location: :string,
    quiet: :boolean,
    # colors options
    no_colors: :boolean,
    expr_color: :string,
    type_color: :string,
    underscore_color: :string
  ]

  @impl Mix.Task
  def run(args) do
    IO.inspect(args, label: "Args")
    {parsed, paths, _invalid} = OptionParser.parse(args, strict: @options)
    # Compile the project before the analysis
    Mix.Tasks.Compile.run([])

    files = get_beams_paths()
    # IO.puts("Found files:\n #{Enum.join(Enum.concat(Map.values(files)), "\n ")}")

    Application.ensure_all_started(:gradualizer)

    :gradualizer_db.import_beam_files(get_deps_beam_paths())

    IO.puts("Typechecking files...")

    res =
      files
      |> Enum.map(fn
        {nil, paths} ->
          Enum.map(paths, &Gradient.type_check_file/1)

        {app_path, paths} ->
          Enum.map(paths, &Gradient.type_check_file(&1, app_path: app_path))
      end)
      |> Enum.concat()

    if Enum.all?(res, &(&1 == :ok)) do
      IO.puts("No problems found!")
    end

    :ok
  end

  def get_beams_paths() do
    if Mix.Project.umbrella?() do
      get_umbrella_app_beams_paths()
    else
      get_app_beams_paths()
    end
  end

  def get_app_beams_paths() do
    %{
      nil =>
        (Mix.Project.app_path() <> "/ebin/**/*.beam")
        |> Path.wildcard()
        |> Enum.map(&String.to_charlist/1)
    }
  end

  def get_umbrella_app_beams_paths() do
    Mix.Project.apps_paths()
    |> Enum.map(fn {app_name, app_path} ->
      app_name = Atom.to_string(app_name)

      paths =
        (Mix.Project.build_path() <> "/lib/" <> app_name <> "/ebin/**/*.beam")
        |> Path.wildcard()
        |> Enum.map(&String.to_charlist/1)

      {app_path, paths}
    end)
    |> Map.new()
  end

  def get_deps_beam_paths() do
    (Mix.Project.build_path() <> "/lib/*/**/*.beam")
    |> Path.wildcard()
    |> Enum.map(&String.to_charlist/1)
  end
end
