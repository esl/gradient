ExUnit.start()

defmodule TestHelper do
  def compile_test_examples(examples_path) do
    ex_blob = examples_path <> "/*.ex"

    for path <- Path.wildcard(ex_blob) do
      System.cmd("elixirc", ["-o", examples_path, path])
    end
  end
end

TestHelper.compile_test_examples("test/examples")
TestHelper.compile_test_examples("test/examples/basic")
TestHelper.compile_test_examples("test/examples/conditional")
