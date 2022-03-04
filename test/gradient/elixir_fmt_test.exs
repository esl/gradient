defmodule Gradient.ElixirFmtTest do
  use ExUnit.Case
  doctest Gradient.ElixirFmt

  alias Gradient.ElixirFmt
  import Gradient.TestHelpers
  alias Gradient.AstSpecifier

  @example_module_path "test/examples/simple_app.ex"

  setup_all config do
    config
    |> load_wrong_ret_error_examples()
    |> load_record_type_example()
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
    test "return integer() instead of atom()", %{wrong_ret_errors: errors} do
      [expected, actual] = type_format_error_to_binary(errors.ret_wrong_atom)

      assert String.contains?(expected, "atom()")
      assert String.contains?(actual, "1")
    end

    test "return tuple() instead of atom()", %{wrong_ret_errors: errors} do
      [expected, actual] = type_format_error_to_binary(errors.ret_wrong_atom2)

      assert String.contains?(expected, "atom()")
      assert String.contains?(actual, "{:ok, []}")
    end

    test "return map() instead of atom()", %{wrong_ret_errors: errors} do
      [expected, actual] = type_format_error_to_binary(errors.ret_wrong_atom3)

      assert String.contains?(expected, "atom()")
      assert String.contains?(actual, "%{required(:a) => 1}")
    end

    test "return float() instead of integer()", %{wrong_ret_errors: errors} do
      [expected, actual] = type_format_error_to_binary(errors.ret_wrong_integer)

      assert String.contains?(expected, "integer()")
      assert String.contains?(actual, "float()")
    end

    test "return atom() instead of integer()", %{wrong_ret_errors: errors} do
      [expected, actual] = type_format_error_to_binary(errors.ret_wrong_integer2)

      assert String.contains?(expected, "integer()")
      assert String.contains?(actual, ":ok")
    end

    test "return boolean() instead of integer()", %{wrong_ret_errors: errors} do
      [expected, actual] = type_format_error_to_binary(errors.ret_wrong_integer3)

      assert String.contains?(expected, "integer()")
      assert String.contains?(actual, "true")
    end

    test "return list() instead of integer()", %{wrong_ret_errors: errors} do
      [expected, actual] = type_format_error_to_binary(errors.ret_wrong_integer4)

      assert String.contains?(expected, "integer()")
      assert String.contains?(actual, "nonempty_list()")
    end

    test "return integer() out of the range()", %{wrong_ret_errors: errors} do
      [expected, actual] = type_format_error_to_binary(errors.ret_out_of_range_int)

      assert String.contains?(expected, "1..10")
      assert String.contains?(actual, "12")
    end

    test "return integer() instead of float()", %{wrong_ret_errors: errors} do
      [expected, actual] = type_format_error_to_binary(errors.ret_wrong_float)

      assert String.contains?(expected, "float()")
      assert String.contains?(actual, "1")
    end

    test "return nil() instead of float()", %{wrong_ret_errors: errors} do
      [expected, actual] = type_format_error_to_binary(errors.ret_wrong_float2)

      assert String.contains?(expected, "float()")
      assert String.contains?(actual, "nil")
    end

    test "return charlist() instead of char()", %{wrong_ret_errors: errors} do
      [expected, actual] = type_format_error_to_binary(errors.ret_wrong_char)

      assert String.contains?(expected, "char()")
      assert String.contains?(actual, "nonempty_list()")
    end

    test "return nil() instead of char()", %{wrong_ret_errors: errors} do
      [expected, actual] = type_format_error_to_binary(errors.ret_wrong_char2)

      # unfortunately char is represented as {:integer, 0, _}
      assert String.contains?(expected, "111")
      assert String.contains?(actual, "nil")
    end

    test "return atom() instead of boolean()", %{wrong_ret_errors: errors} do
      [expected, actual] = type_format_error_to_binary(errors.ret_wrong_boolean)

      assert String.contains?(expected, "boolean()")
      assert String.contains?(actual, ":ok")
    end

    test "return binary() instead of boolean()", %{wrong_ret_errors: errors} do
      [expected, actual] = type_format_error_to_binary(errors.ret_wrong_boolean2)

      assert String.contains?(expected, "boolean()")
      assert String.contains?(actual, "binary()")
    end

    test "return integer() instead of boolean()", %{wrong_ret_errors: errors} do
      [expected, actual] = type_format_error_to_binary(errors.ret_wrong_boolean3)

      assert String.contains?(expected, "boolean()")
      assert String.contains?(actual, "1")
    end

    test "return keyword() instead of boolean()", %{wrong_ret_errors: errors} do
      [expected, actual] = type_format_error_to_binary(errors.ret_wrong_boolean4)

      assert String.contains?(expected, "boolean()")
      assert String.contains?(actual, "nonempty_list()")
    end

    test "return list() instead of keyword()", %{wrong_ret_errors: errors} do
      [expected, actual] = type_format_error_to_binary(errors.ret_wrong_keyword)

      assert String.contains?(expected, "{atom(), any()}")
      assert String.contains?(actual, "1")
    end

    test "return tuple() instead of map()", %{wrong_ret_errors: errors} do
      [expected, actual] = type_format_error_to_binary(errors.ret_wrong_map)

      assert String.contains?(expected, "map()")
      assert String.contains?(actual, "{:a, 1, 2}")
    end

    test "return lambda with wrong returned type", %{wrong_ret_errors: errors} do
      [expected, actual] = type_format_error_to_binary(errors.ret_wrong_fun)

      assert String.contains?(expected, "atom()")
      assert String.contains?(actual, "12")
    end

    test "return atom() instead of record()", %{record_type_errors: errors} do
      [expected, actual] = type_format_error_to_binary(errors.ret_wrong_record)

      assert String.contains?(expected, "user()")
      assert String.contains?(actual, ":ok")
    end

    test "return wrong record value type", %{record_type_errors: errors} do
      [expected, actual] = type_format_error_to_binary(errors.ret_wrong_record2)

      assert String.contains?(expected, "String.t()")
      assert String.contains?(actual, "12")
    end
  end

  describe "expression format" do
    test "atom", %{wrong_ret_errors: errors} do
      expr = expr_format_error_to_binary(errors.ret_wrong_integer2)
      assert String.contains?(expr, ":ok")
    end

    test "integer", %{wrong_ret_errors: errors} do
      expr = expr_format_error_to_binary(errors.ret_wrong_atom)
      assert String.contains?(expr, "1")
    end

    test "float", %{wrong_ret_errors: errors} do
      expr = expr_format_error_to_binary(errors.ret_wrong_integer)
      assert String.contains?(expr, "1.0")
    end

    test "list", %{wrong_ret_errors: errors} do
      expr = expr_format_error_to_binary(errors.ret_wrong_integer4)
      assert String.contains?(expr, "[1, 2, 3]")
    end

    test "map", %{wrong_ret_errors: errors} do
      expr = expr_format_error_to_binary(errors.ret_wrong_tuple)
      assert String.contains?(expr, "%{a: 1, b: 2}")
    end

    test "tuple", %{wrong_ret_errors: errors} do
      expr = expr_format_error_to_binary(errors.ret_wrong_map)
      assert String.contains?(expr, "{:a, 1, 2}")
    end

    test "string", %{wrong_ret_errors: errors} do
      expr = expr_format_error_to_binary(errors.ret_wrong_boolean2)
      assert String.contains?(expr, ~s("1234"))
    end

    test "char", %{wrong_ret_errors: errors} do
      expr = expr_format_error_to_binary(errors.ret_wrong_list)
      # I don't know if it is possible to detect that we want char here.
      assert String.contains?(expr, "99")
    end

    test "charlist", %{wrong_ret_errors: errors} do
      expr = expr_format_error_to_binary(errors.ret_wrong_char)
      assert String.contains?(expr, "'Ala ma kota'")
    end

    test "record", %{record_type_errors: errors} do
      expr = expr_format_error_to_binary(errors.ret_wrong_atom)
      assert String.contains?(expr, ~s({:user, "Kate", 25}))
    end

    test "call", %{wrong_ret_errors: errors} do
      expr = expr_format_error_to_binary(errors.ret_wrong_call)
      assert String.contains?(expr, "ret_wrong_boolean()")
    end

    test "fun reference", %{wrong_ret_errors: errors} do
      expr = expr_format_error_to_binary(errors.ret_wrong_integer5)
      assert String.contains?(expr, "&ret_wrong_atom/0")
    end
  end

  describe "spec" do
    test "name doesn't match the function name" do
      msg =
        {:spec_error, :wrong_spec_name, 3, :convert, 1}
        |> ElixirFmt.format_error([])
        |> :erlang.iolist_to_binary()

      assert "The spec convert/1 on line 3 doesn't match the function name/arity\n" = msg
    end

    test "follows another spec" do
      msg =
        {:spec_error, :spec_after_spec, 3, :convert, 1}
        |> ElixirFmt.format_error([])
        |> :erlang.iolist_to_binary()

      assert "The spec convert/1 on line 3 follows another spec when only one spec per function clause is allowed\n" =
               msg
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

  defp expr_format_error_to_binary(error, opts \\ []) do
    opts = Keyword.put_new(opts, :ex_fmt_type_fun, &mock_fmt/1)
    opts = Keyword.put_new(opts, :ex_colors, use_colors: false)

    error
    |> ElixirFmt.format_error(opts)
    |> :erlang.iolist_to_binary()
    |> String.split("on line")
    |> List.first()
  end

  defp type_format_error_to_binary(error, opts \\ []) do
    opts = Keyword.put_new(opts, :ex_fmt_expr_fun, &mock_fmt/1)
    opts = Keyword.put_new(opts, :ex_colors, use_colors: false)

    error
    |> ElixirFmt.format_error(opts)
    |> :erlang.iolist_to_binary()
    |> String.split("have type")
    |> List.last()
    |> String.split("but it has type")
  end

  @spec load_record_type_example(map()) :: map()
  defp load_record_type_example(config) do
    {_tokens, ast} = load("type/Elixir.RecordEx.beam", "type/record.ex")

    {errors, forms} = type_check_file(ast, [])

    names =
      get_function_names_from_ast(forms)
      |> Enum.drop(3)

    errors_map =
      Enum.zip(names, errors)
      |> Map.new()

    Map.put(config, :record_type_errors, errors_map)
  end

  @spec load_wrong_ret_error_examples(map()) :: map()
  defp load_wrong_ret_error_examples(config) do
    {_tokens, ast} = load("type/Elixir.WrongRet.beam", "type/wrong_ret.ex")

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

  def mock_fmt(_), do: ""
end
