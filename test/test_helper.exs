ExUnit.start()

defmodule ExamplesCompiler do
  @build_path "test/examples/_build/"

  def compile(pattern) do
    case File.mkdir(@build_path) do
      :ok ->
        paths = Path.wildcard(pattern)
        Kernel.ParallelCompiler.compile_to_path(paths, @build_path)
        :ok

      _ ->
        :error
    end
  end
end

ExamplesCompiler.compile("test/examples/**/*.ex")
