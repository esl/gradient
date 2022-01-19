defmodule Gradient.ExprData do
  require Gradient.Debug
  import Gradient.Debug, only: [elixir_to_ast: 1]

  def all_basic_pp_test_data() do
    [
      value_test_data(),
      list_test_data(),
      call_test_data(),
      variable_test_data(),
      exception_test_data(),
      block_test_data(),
      binary_test_data(),
      map_test_data()
    ]
    |> List.flatten()
  end

  def value_test_data() do
    [
      {"geric atom", {:atom, 0, :fjdksaose}, ":fjdksaose"},
      {"module atom", {:atom, 0, Gradient.ElixirExpr}, "Gradient.ElixirExpr"},
      {"nil atom", {:atom, 0, nil}, "nil"},
      {"true atom", {:atom, 0, true}, "true"},
      {"false atom", {:atom, 0, false}, "false"},
      {"char", {:char, 0, ?c}, "?c"},
      {"float", {:float, 0, 12.0}, "12.0"},
      {"integer", {:integer, 0, 1}, "1"},
      {"erlang string", {:string, 0, 'ala ma kota'}, "\'ala ma kota\'"}
    ]
  end

  def list_test_data() do
    [
      {"charlist",
       {:cons, 0, {:integer, 0, 97},
        {:cons, 0, {:integer, 0, 108}, {:cons, 0, {:integer, 0, 97}, {nil, 0}}}}, "\'ala\'"},
      {"int list",
       {:cons, 0, {:integer, 0, 0},
        {:cons, 0, {:integer, 0, 1}, {:cons, 0, {:integer, 0, 2}, {nil, 0}}}}, "[0, 1, 2]"},
      {"mixed list",
       {:cons, 0, {:integer, 0, 0},
        {:cons, 0, {:atom, 0, :ok}, {:cons, 0, {:integer, 0, 2}, {nil, 0}}}}, "[0, :ok, 2]"}
    ]
  end

  def call_test_data() do
    [
      {"call", {:call, 0, {:atom, 0, :my_func}, []}, "my_func()"},
      {"remote call", {:call, 0, {:remote, 0, {:atom, 0, MyModule}, {:atom, 0, :my_func}}, []},
       "MyModule.my_func()"},
      {"erl remote call", {:call, 0, {:remote, 0, {:atom, 0, :erlang}, {:atom, 0, :my_func}}, []},
       ":erlang.my_func()"}
    ]
  end

  def variable_test_data() do
    [
      {"variable", {:var, 0, :abbc}, "abbc"},
      {"underscore variable", {:var, 0, :_}, "_"},
      {"ast underscore variable", {:var, 0, :_@1}, "_"},
      {"ast variable", {:var, 0, :_val@1}, "val"}
    ]
  end

  def exception_test_data() do
    [
      {"throw", elixir_to_ast(throw({:ok, 12})), "throw {:ok, 12}"},
      {"raise/1", elixir_to_ast(raise "test error"), "raise \"test error\""},
      {"raise/2", elixir_to_ast(raise RuntimeError, "test error"), "raise \"test error\""},
      {"custom raise", elixir_to_ast(raise ArithmeticError, "only odd numbers"),
       "raise ArithmeticError, \"only odd numbers\""}
    ]
  end

  def block_test_data() do
    simple_block =
      elixir_to_ast do
        a = 1
        a + 1
      end

    [
      {"block", simple_block, "a = 1; a + 1"}
    ]
  end

  def map_test_data do
    [
      {"map pm", elixir_to_ast(%{a: a} = %{a: 12}), "%{a: a} = %{a: 12}"},
      {"struct expr", elixir_to_ast(%{__struct__: TestStruct, name: "John"}),
       "%TestStruct{name: \"John\"}"}
    ]
  end

  def binary_test_data do
    [
      bin_pm_bin_var(),
      bin_joining_syntax(),
      bin_with_bin_var(),
      bin_with_pp_int_size(),
      bin_with_pp_and_bitstring_size()
    ]
  end

  defp bin_pm_bin_var do
    ast =
      elixir_to_ast do
        <<a::8, _rest::binary>> = <<1, 2, 3, 4>>
      end

    {"bin pattern matching with bin var", ast, "<<a::8, _rest::binary>> = <<1, 2, 3, 4>>"}
  end

  defp bin_joining_syntax do
    ast =
      elixir_to_ast do
        x = "b"
        "a" <> x
      end

    {"binary <> joining", ast, "x = \"b\"; <<\"a\", x::binary>>"}
  end

  defp bin_with_bin_var do
    ast =
      elixir_to_ast do
        x = "b"
        <<"a", "b", x::binary>>
      end

    {"binary with bin var", ast, "x = \"b\"; <<\"a\", \"b\", x::binary>>"}
  end

  defp bin_with_pp_int_size do
    ast =
      elixir_to_ast do
        <<a::16>> = <<"abcd">>
      end

    {"binary with int size", ast, "<<a::16>> = \"abcd\""}
  end

  defp bin_with_pp_and_bitstring_size do
    ast =
      elixir_to_ast do
        <<header::8, length::32, message::bitstring-size(144)>> =
          <<1, 2, 3, 4, 5, 101, 114, 97, 115, 101, 32, 116, 104, 101, 32, 101, 118, 105, 100, 101,
            110, 99, 101>>
      end

    expected =
      "<<header::8, length::32, message::bitstring-size(144)>> = <<1, 2, 3, 4, 5, 101, 114, 97, 115, 101, 32, 116, 104, 101, 32, 101, 118, 105, 100, 101, 110, 99, 101>>"

    {"binary with patter matching and bitstring-size", ast, expected}
  end
end
