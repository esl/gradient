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

  def basic_erlang_forms() do
    [{:attribute, 1, :file, {@example_module_path, 1}}]
  end

end
