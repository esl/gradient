defmodule GradualizerEx.SpecifyErlAstTest do
  use ExUnit.Case
  doctest GradualizerEx.SpecifyErlAst

  alias GradualizerEx.SpecifyErlAst

  test "add_missing_loc_literals/2" do
    {tokens, ast} = example_data() 
    new_ast = SpecifyErlAst.add_missing_loc_literals(tokens, ast)
  end

  test "specify_line/2" do
    {tokens, _} = example_data()

    form =
      assert {{:integer, 21, 12}, tokens} = SpecifyErlAst.specify_line({:integer, 21, 12}, tokens)

    assert {{:integer, 22, 12}, _tokens} = SpecifyErlAst.specify_line({:integer, 20, 12}, tokens)
  end


  def example_data() do
    beam_path = 'examples/simple_app/_build/dev/lib/simple_app/ebin/Elixir.SimpleApp.beam'
    file_path = "examples/simple_app/lib/simple_app.ex"

      code = File.read!(file_path)
      |> String.to_charlist()

    {:ok, tokens} =
      code
      |> :elixir.string_to_tokens(1, 1, file_path, [])

    {:ok, {SimpleApp, [abstract_code: {:raw_abstract_v1, ast}]}} =
      :beam_lib.chunks(beam_path, [:abstract_code])

    {tokens, ast}
  end
end
