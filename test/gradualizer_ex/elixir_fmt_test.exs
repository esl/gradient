defmodule GradualizerEx.ElixirFmtTest do
  use ExUnit.Case
  doctest GradualizerEx.ElixirFmt

  alias GradualizerEx.ElixirFmt

  @example_module_path "test/examples/simple_app.ex"

  test "try_highlight_in_context/2" do
    opts = [forms: basic_erlang_forms()]
    expression = {:integer, 31, 12}

    res = ElixirFmt.try_highlight_in_context(expression, opts)

    expected = "29   def bool_id(x) do\n30     _x = 13\n\e[4m\e[31m31     12\e[0m\n32   end\n33 "
    assert res == expected
  end

  @tag :skip
  test "format_expr_type_error/4" do
    opts = [forms: basic_erlang_forms()]
    expression = {:integer, 0, 12}
    actual_type = expression
    expected_type = {:type, 0, :boolean, []}

    res = ElixirFmt.format_expr_type_error(expression, actual_type, expected_type, opts)
    IO.puts(res)
  end

  test "get_block_lines/1" do
    ast = example_block_ast()

    assert [30, 31, 32] == ElixirFmt.get_block_lines(ast)
  end

  def basic_erlang_forms() do
    [{:attribute, 1, :file, {@example_module_path, 1}}]
  end

  def example_block_ast() do
    {:__block__, [],
     [
       {:=, [line: 30], [{:_x, [line: 30], nil}, 12]},
       {:=, [line: 31], [{:_x, [line: 31], nil}, 12]},
       :ok
     ]}
  end
end
