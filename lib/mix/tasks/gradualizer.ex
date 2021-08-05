defmodule Mix.Tasks.Gradualizer do
  use Mix.Task

  @impl Mix.Task
  def run(_args) do
    # Starting app to format logger 
    # Mix.Task.run("app.start")
    # Compile the project before the analysis
    Mix.Tasks.Compile.run([])
    files = get_app_beam_paths()
    IO.puts("Found files:\n #{Enum.join(files, "\n ")}")

    Application.ensure_all_started(:gradualizer)

    (files ++ get_deps_beam_paths())
    |> :gradualizer_db.import_beam_files()

    IO.puts("Gradualizing files...")
    res = Enum.map(files, &GradualizerEx.type_check_file(&1))

    if Enum.all?(res, &(&1 == :ok)) do
      IO.puts("No problems found!")
    end

    :ok
  end

  def get_app_beam_paths() do
    (Mix.Project.app_path() <> "/ebin/**/*.beam")
    |> Path.wildcard()
    |> Enum.map(&String.to_charlist/1)
  end

  def get_deps_beam_paths() do
    Mix.Project.deps_paths()
    |> Enum.map(fn {_, path} -> Path.wildcard(path <> "/ebin/**/*.beam") end)
    |> Enum.concat()
    |> Enum.map(&to_charlist/1)
  end
end
