defmodule Mix.Tasks.Gradualizer do

  use Mix.Task
  
  @impl Mix.Task
  def run(_args) do
    Mix.Tasks.Compile.run([])
    files = get_app_paths()
    GradualizerEx.type_check_files(files)
    :ok
  end

  def get_app_paths() do
    ebin_path = Mix.Project.app_path() <> "/ebin"
    blob = ebin_path <> "/*.beam"
    Path.wildcard(blob)
    |> Enum.map(&String.to_charlist/1)
  end
  
end
