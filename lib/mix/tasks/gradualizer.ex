defmodule Mix.Tasks.Gradualizer do
  use Mix.Task

  @impl Mix.Task
  def run(_args) do
    # Starting app to format logger 
    # Mix.Task.run("app.start")
    # Compile the project before the analysis
    Mix.Tasks.Compile.run([])
    files = get_app_paths()
    IO.puts("Found files:\n #{Enum.join(files, "\n ")}")

    IO.puts("Gradualizing files...")
    res = Enum.map(files, &GradualizerEx.type_check_file(&1))

    if Enum.all?(res, &(&1 == :ok)) do
      IO.puts("No problems found!")
    end

    :ok
  end

  def get_app_paths() do
    ebin_path = Mix.Project.app_path() <> "/ebin"
    blob = ebin_path <> "/*.beam"

    Path.wildcard(blob)
    |> Enum.map(&String.to_charlist/1)
  end
end
