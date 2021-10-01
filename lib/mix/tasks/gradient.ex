defmodule Mix.Tasks.Gradient do
  use Mix.Task

  @impl Mix.Task
  def run(_args) do
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
