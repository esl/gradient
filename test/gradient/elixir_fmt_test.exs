defmodule Gradient.ElixirFmtTest do
  use ExUnit.Case
  doctest Gradient.ElixirFmt

  alias Gradient.ElixirFmt
  import Gradient.TestHelpers
  alias Gradient.AstSpecifier

  @example_module_path "test/examples/simple_app.ex"

  test "try_highlight_in_context/2" do
    opts = [forms: basic_erlang_forms()]
    expression = {:integer, 31, 12}

    res = ElixirFmt.try_highlight_in_context(expression, opts)

    expected =
      {:ok, "29   def bool_id(x) do\n30     _x = 13\n\e[4m\e[31m31     12\e[0m\n32   end\n33 "}

    assert res == expected
  end

  @tag :skip
  describe "types format" do
    test "wrong return type" do
      {_tokens, ast} = load("/type/Elixir.WrongRet.beam", "/type/wrong_ret.ex")
      opts = []
      errors = type_check_file(ast, opts)

      for e <- errors do
        :io.put_chars(e)
      end
    end
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

  def type_check_file(ast, opts) do
    forms = AstSpecifier.specify(ast)
    opts = Keyword.put(opts, :return_errors, true)
    opts = Keyword.put(opts, :forms, forms)

    forms
    |> :gradualizer.type_check_forms(opts)
    |> Enum.map(fn {_, err} -> ElixirFmt.format_error(err, opts) end)
  end
end
