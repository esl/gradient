defmodule Gradient.ElixirFmtTest do
  use ExUnit.Case
  doctest Gradient.ElixirFmt

  alias Gradient.ElixirFmt
  import Gradient.TestHelpers
  alias Gradient.AstSpecifier

  @example_module_path "test/examples/simple_app.ex"

  setup_all config do
    load_wrong_ret_error_examples(config)
  end

  test "try_highlight_in_context/2" do
    opts = [forms: basic_erlang_forms()]
    expression = {:integer, 31, 12}

    res = ElixirFmt.try_highlight_in_context(expression, opts)

    expected =
      {:ok, "29   def bool_id(x) do\n30     _x = 13\n\e[4m\e[31m31     12\e[0m\n32   end\n33 "}

    assert res == expected
  end

  describe "types format" do
    test "return integer() instead atom()", %{wrong_ret_errors: errors} do
      msg = format_error_to_binary(errors.ret_wrong_atom)

      assert String.contains?(msg, "atom()")
      assert String.contains?(msg, "1")
    end

    test "return tuple() instead atom()", %{wrong_ret_errors: errors} do
      msg = format_error_to_binary(errors.ret_wrong_atom2)

      assert String.contains?(msg, "atom()")
      assert String.contains?(msg, "{:ok, []}")
    end

    test "return map() instead atom()", %{wrong_ret_errors: errors} do
      msg = format_error_to_binary(errors.ret_wrong_atom3)

      assert String.contains?(msg, "atom()")
      assert String.contains?(msg, "%{required(:a) => 1}")
    end

    test "return float() instead integer()", %{wrong_ret_errors: errors} do
      msg = format_error_to_binary(errors.ret_wrong_integer)

      assert String.contains?(msg, "integer()")
      assert String.contains?(msg, "1.0")
    end

    test "return atom() instead integer()", %{wrong_ret_errors: errors} do
      msg = format_error_to_binary(errors.ret_wrong_integer2)

      assert String.contains?(msg, "integer()")
      assert String.contains?(msg, ":ok")
    end

    test "return boolean() instead integer()", %{wrong_ret_errors: errors} do
      msg = format_error_to_binary(errors.ret_wrong_integer3)

      assert String.contains?(msg, "integer()")
      assert String.contains?(msg, "true")
    end

    test "return list() instead integer()", %{wrong_ret_errors: errors} do
      msg = format_error_to_binary(errors.ret_wrong_integer4)

      assert String.contains?(msg, "integer()")
      assert String.contains?(msg, "nonempty_list()")
    end

    test "return integer() out of the range()", %{wrong_ret_errors: errors} do
      msg = format_error_to_binary(errors.ret_out_of_range_int)

      assert String.contains?(msg, "range(1, 10)")
      assert String.contains?(msg, "12")
    end

    test "return atom() instead boolean()", %{wrong_ret_errors: errors} do
      msg = format_error_to_binary(errors.ret_wrong_boolean)

      assert String.contains?(msg, "boolean()")
      assert String.contains?(msg, ":ok")
    end

    test "return binary() instead boolean()", %{wrong_ret_errors: errors} do
      msg = format_error_to_binary(errors.ret_wrong_boolean2)

      assert String.contains?(msg, "boolean()")
      assert String.contains?(msg, "binary()")
    end

    test "return integer() instead boolean()", %{wrong_ret_errors: errors} do
      msg = format_error_to_binary(errors.ret_wrong_boolean3)

      assert String.contains?(msg, "boolean()")
      assert String.contains?(msg, "1")
    end

    test "return keyword() instead boolean()", %{wrong_ret_errors: errors} do
      msg = format_error_to_binary(errors.ret_wrong_boolean4)

      assert String.contains?(msg, "boolean()")
      assert String.contains?(msg, "nonempty_list()")
    end

    test "return list() instead keyword()", %{wrong_ret_errors: errors} do
      msg = format_error_to_binary(errors.ret_wrong_keyword)

      assert String.contains?(msg, "{atom(), any()}")
      assert String.contains?(msg, "1")
    end

    test "return tuple() instead map()", %{wrong_ret_errors: errors} do
      msg = format_error_to_binary(errors.ret_wrong_map)

      assert String.contains?(msg, "map()")
      assert String.contains?(msg, "{:a, 1, 2}")
    end

    test "return lambda with wrong returned type", %{wrong_ret_errors: errors} do
      msg = format_error_to_binary(errors.ret_wrong_fun)

      assert String.contains?(msg, "atom()")
      assert String.contains?(msg, "12")
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

  # Helpers

  defp basic_erlang_forms() do
    [{:attribute, 1, :file, {@example_module_path, 1}}]
  end

  defp type_check_file(ast, opts) do
    forms = AstSpecifier.specify(ast)
    opts = Keyword.put(opts, :return_errors, true)
    opts = Keyword.put(opts, :forms, forms)

    errors =
      forms
      |> :gradualizer.type_check_forms(opts)
      |> Enum.map(&elem(&1, 1))

    {errors, forms}
  end

  defp format_error_to_binary(error, opts \\ []) do
    error
    |> ElixirFmt.format_error(opts)
    |> :erlang.iolist_to_binary()
  end

  @spec load_wrong_ret_error_examples(map()) :: map()
  defp load_wrong_ret_error_examples(config) do
    {_tokens, ast} = load("/type/Elixir.WrongRet.beam", "/type/wrong_ret.ex")

    {errors, forms} = type_check_file(ast, [])
    names = get_function_names_from_ast(forms)

    errors_map =
      Enum.zip(names, errors)
      |> Map.new()

    Map.put(config, :wrong_ret_errors, errors_map)
  end

  @spec get_function_names_from_ast([tuple()]) :: [atom()]
  def get_function_names_from_ast(ast) do
    ast
    |> Enum.filter(fn
      {:function, _, name, _, _} -> name != :__info__
      _ -> false
    end)
    |> Enum.map(&elem(&1, 2))
  end
end
