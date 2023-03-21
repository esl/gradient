defmodule Gradient.GeneratedCodeTest do
  @moduledoc false
  use ExUnit.Case
  import ExUnit.CaptureIO
  import Gradient.TestHelpers

  alias Gradient.AstSpecifier
  alias Gradient.AstData

  test "generated code is tagged as such in AST" do
    {tokens, ast} = load("Elixir.GeneratedCode.beam", "generated_code.ex")

    # TODO check to make sure generated code is tagged as generated, similar to
    # test/gradient/ast_specifier_test.exs:161
    # For now, invalid assert to force it to print out
    assert [] = AstSpecifier.run_mappers(ast, tokens) |> Enum.reverse()
  end

  test "module with generated code doesn't emit warning" do
    output =
      capture_io(fn ->
        assert [:ok] = Gradient.type_check_file("test/examples/_build/Elixir.GeneratedCode.beam")
      end)

    assert "" == output
  end
end
