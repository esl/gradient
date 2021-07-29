defmodule GradualizerEx.SpecifyErlAstTest do
  use ExUnit.Case
  doctest GradualizerEx.SpecifyErlAst

  alias GradualizerEx.SpecifyErlAst

  import GradualizerEx.Utils

  @examples_path "test/examples"

  test "add_missing_loc_literals/2" do
    {tokens, ast} = example_data()
    new_ast = SpecifyErlAst.add_missing_loc_literals(tokens, ast)

    assert is_list(new_ast)
  end

  test "specify_line/2" do
    {tokens, _} = example_data()

    assert {{:integer, 21, 12}, tokens} = SpecifyErlAst.specify_line({:integer, 21, 12}, tokens)

    assert {{:integer, 22, 12}, _tokens} = SpecifyErlAst.specify_line({:integer, 20, 12}, tokens)
  end

  test "cons_to_charlist/1" do
    cons =
      {:cons, 0, {:integer, 0, 49},
       {:cons, 0, {:integer, 0, 48}, {:cons, 0, {:integer, 0, 48}, {nil, 0}}}}

    assert '100' == SpecifyErlAst.cons_to_charlist(cons)
  end

  test "get_list_from_tokens" do
    tokens = example_string_tokens()
    ts = drop_tokens_to_line(tokens, 5)
    assert {:charlist, _} = SpecifyErlAst.get_list_from_tokens(ts)

    ts = drop_tokens_to_line(ts, 7)
    assert {:list, _} = SpecifyErlAst.get_list_from_tokens(ts)
  end

  describe "test that prints result" do
    @tag :skip
    test "specify/1" do
      {_tokens, forms} = example_data()

      SpecifyErlAst.specify(forms)
      |> IO.inspect()
    end

    @tag :skip
    test "display forms" do
      {_, forms} = example_data()
      IO.inspect(forms)
    end
  end

  def example_data() do
    beam_path = (@examples_path <> "/Elixir.SimpleApp.beam") |> String.to_charlist()
    file_path = @examples_path <> "/simple_app.ex"

    code =
      File.read!(file_path)
      |> String.to_charlist()

    {:ok, tokens} =
      code
      |> :elixir.string_to_tokens(1, 1, file_path, [])

    {:ok, {SimpleApp, [abstract_code: {:raw_abstract_v1, ast}]}} =
      :beam_lib.chunks(beam_path, [:abstract_code])

    ast = replace_file_path(ast, file_path)
    {tokens, ast}
  end

  def example_string_tokens() do
    file_path = @examples_path <> "/string_test.ex"

    code =
      File.read!(file_path)
      |> String.to_charlist()

    {:ok, tokens} =
      code
      |> :elixir.string_to_tokens(1, 1, file_path, [])

    tokens
  end

  def replace_file_path([_ | forms], path) do
    path = String.to_charlist(path)
    [{:attribute, 1, :file, {path, 1}} | forms]
  end
end
