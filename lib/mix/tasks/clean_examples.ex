defmodule Mix.Tasks.CleanExamples do
  @moduledoc """
  Mix task for removing compiled files under test/examples/_build and
  test/examples/erlang/_build. Useful for getting a clean build for tests.
  """

  use Mix.Task

  @example_dirs [
    "test/examples/_build",
    "test/examples/erlang/_build"
  ]

  @impl Mix.Task
  def run(_args) do
    IO.puts("Cleaning compiled examples in: " <> inspect(@example_dirs))
    Enum.each(@example_dirs, &File.rm_rf!/1)
  end
end
