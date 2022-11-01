defmodule Mix.Tasks.CleanExamples do
  @moduledoc """
  Mix task for removing compiled files under test/examples/_build and
  test/examples/erlang/_build. Useful for getting a clean build for tests.
  """

  use Mix.Task

  @impl Mix.Task
  def run(_args) do
    File.rm_rf!("test/examples/_build")
    File.rm_rf!("test/examples/erlang/_build")
  end
end
