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
      map_test_data(),
      function_ref_test_data(),
      sigil_test_data()
    ]
    |> List.flatten()
  end

  def value_test_data() do
    [
      {"geric atom", {:atom, 0, :fjdksaose}, ~s(:"fjdksaose")},
      {"module atom", {:atom, 0, Gradient.ElixirExpr}, "Gradient.ElixirExpr"},
      {"nil atom", {:atom, 0, nil}, "nil"},
      {"true atom", {:atom, 0, true}, "true"},
      {"false atom", {:atom, 0, false}, "false"},
      {"char", {:char, 0, ?c}, "?c"},
      {"float", {:float, 0, 12.0}, "12.0"},
      {"integer", {:integer, 0, 1}, "1"},
      {"erlang string", {:string, 0, 'ala ma kota'}, ~s('ala ma kota')},
      {"remote name", {:remote, 7, {:atom, 7, Exception}, {:atom, 7, :normalize}},
       "Exception.normalize"}
    ]
  end

  def list_test_data() do
    [
      {"charlist",
       {:cons, 0, {:integer, 0, 97},
        {:cons, 0, {:integer, 0, 108}, {:cons, 0, {:integer, 0, 97}, {nil, 0}}}}, ~s('ala')},
      {"int list",
       {:cons, 0, {:integer, 0, 0},
        {:cons, 0, {:integer, 0, 1}, {:cons, 0, {:integer, 0, 2}, {nil, 0}}}}, "[0, 1, 2]"},
      {"mixed list",
       {:cons, 0, {:integer, 0, 0},
        {:cons, 0, {:atom, 0, :ok}, {:cons, 0, {:integer, 0, 2}, {nil, 0}}}}, ~s([0, :"ok", 2])},
      {"var in list", {:cons, 0, {:integer, 0, 0}, {:cons, 0, {:var, 0, :a}, {nil, 0}}},
       "[0, a]"},
      {"list tail pm", elixir_to_ast([a | t] = [12, 13, 14]), "[a | t] = [12, 13, 14]"},
      {"empty list", elixir_to_ast([] = []), "[] = []"}
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
      {"throw", elixir_to_ast(throw({:ok, 12})), ~s(throw {:"ok", 12})},
      {"raise/1", elixir_to_ast(raise "test error"), ~s(raise "test error")},
      {"raise/1 without msg", elixir_to_ast(raise RuntimeError), "raise RuntimeError"},
      {"raise/2", elixir_to_ast(raise RuntimeError, "test error"), ~s(raise "test error")},
      {"custom raise", elixir_to_ast(raise ArithmeticError, "only odd numbers"),
       ~s(raise ArithmeticError, "only odd numbers")}
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
      {"string map", elixir_to_ast(%{"a" => 12}), ~s(%{"a" => 12})},
      {"map pm", elixir_to_ast(%{a: a} = %{a: 12}), ~s(%{"a": a} = %{"a": 12})},
      {"update map", elixir_to_ast(%{%{} | a: 1}), ~s(%{%{} | "a": 1})},
      {"struct expr", elixir_to_ast(%{__struct__: TestStruct, name: "John"}),
       ~s(%TestStruct{"name": "John"})}
    ]
  end

  def function_ref_test_data() do
    [
      {"&fun/arity", {:fun, 0, {:function, :my_fun, 0}}, "&my_fun/0"},
      {"&Mod.fun/arity", elixir_to_ast(&MyMod.my_fun/1), "&MyMod.my_fun/1"}
    ]
  end

  def sigil_test_data() do
    [
      {"regex", elixir_to_ast(~r/foo|bar/), regex_exp()},
      {"string ~s", elixir_to_ast(~s(this is a string with "double" quotes, not 'single' ones)),
       "\"this is a string with \"double\" quotes, not 'single' ones\""},
      {"string ~S", elixir_to_ast(~S(String without escape codes \x26 without #{interpolation})),
       "\"String without escape codes \\x26 without \#{interpolation}\""},
      {"char lists", elixir_to_ast(~c(this is a char list containing 'single quotes')),
       "'this is a char list containing \\'single quotes\\''"},
      {"word list", elixir_to_ast(~w(foo bar bat)), ~s(["foo", "bar", "bat"])},
      {"word list atom", elixir_to_ast(~w(foo bar bat)a), ~s([:"foo", :"bar", :"bat"])},
      {"date", elixir_to_ast(~D[2019-10-31]),
       ~s(%Date{"calendar": Calendar.ISO, "year": 2019, "month": 10, "day": 31})},
      {"time", elixir_to_ast(~T[23:00:07.0]),
       ~s(%Time{"calendar": Calendar.ISO, "hour": 23, "minute": 0, "second": 7, "microsecond": {0, 1}})},
      {"naive date time", elixir_to_ast(~N[2019-10-31 23:00:07]),
       ~s(%NaiveDateTime{"calendar": Calendar.ISO, "year": 2019, "month": 10, "day": 31, "hour": 23, "minute": 0, "second": 7, "microsecond": {0, 0}})},
      {"date time", elixir_to_ast(~U[2019-10-31 19:59:03Z]),
       ~s(%DateTime{"calendar": Calendar.ISO, "year": 2019, "month": 10, "day": 31, "hour": 19, "minute": 59, "second": 3, "microsecond": {0, 0}, "time_zone": "Etc/UTC", "zone_abbr": "UTC", "utc_offset": 0, "std_offset": 0})}
    ]
  end

  def binary_test_data do
    [
      bin_pm_bin_var(),
      bin_joining_syntax(),
      bin_with_bin_var(),
      bin_with_pp_int_size(),
      bin_with_pp_and_bitstring_size(),
      {"bin float", elixir_to_ast(<<4.3::float>>), "<<(4.3)::float>>"}
    ]
  end

  defp bin_pm_bin_var do
    ast =
      elixir_to_ast do
        <<a::8, _rest::binary>> = <<1, 2, 3, 4>>
      end

    {"bin pattern matching with bin var", ast, "<<(a)::8, (_rest)::binary>> = <<1, 2, 3, 4>>"}
  end

  defp bin_joining_syntax do
    ast =
      elixir_to_ast do
        x = "b"
        "a" <> x
      end

    {"binary <> joining", ast, ~s(x = "b"; <<"a", (x\)::binary>>)}
  end

  defp bin_with_bin_var do
    ast =
      elixir_to_ast do
        x = "b"
        <<"a", "b", x::binary>>
      end

    {"binary with bin var", ast, ~s(x = "b"; <<"a", "b", (x\)::binary>>)}
  end

  defp bin_with_pp_int_size do
    ast =
      elixir_to_ast do
        <<a::16>> = <<"abcd">>
      end

    {"binary with int size", ast, ~s(<<(a\)::16>> = "abcd")}
  end

  defp bin_with_pp_and_bitstring_size do
    ast =
      elixir_to_ast do
        <<header::8, length::32, message::bitstring-size(144)>> =
          <<1, 2, 3, 4, 5, 101, 114, 97, 115, 101, 32, 116, 104, 101, 32, 101, 118, 105, 100, 101,
            110, 99, 101>>
      end

    expected =
      "<<(header)::8, (length)::32, (message)::bitstring-size(144)>> = <<1, 2, 3, 4, 5, 101, 114, 97, 115, 101, 32, 116, 104, 101, 32, 101, 118, 105, 100, 101, 110, 99, 101>>"

    {"binary with patter matching and bitstring-size", ast, expected}
  end

  defp regex_exp() do
    <<37, 82, 101, 103, 101, 120, 123, 34, 111, 112, 116, 115, 34, 58, 32, 60, 60, 62, 62, 44, 32,
      34, 114, 101, 95, 112, 97, 116, 116, 101, 114, 110, 34, 58, 32, 123, 58, 34, 114, 101, 95,
      112, 97, 116, 116, 101, 114, 110, 34, 44, 32, 48, 44, 32, 48, 44, 32, 48, 44, 32, 34, 69,
      82, 67, 80, 86, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 195, 191, 195, 191, 195, 191, 195, 191,
      195, 191, 195, 191, 195, 191, 195, 191, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 64, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 194, 131, 0, 9, 29,
      102, 29, 111, 29, 111, 119, 0, 9, 29, 98, 29, 97, 29, 114, 120, 0, 18, 0, 34, 125, 44, 32,
      34, 114, 101, 95, 118, 101, 114, 115, 105, 111, 110, 34, 58, 32, 123, 34, 56, 46, 52, 52,
      32, 50, 48, 50, 48, 45, 48, 50, 45, 49, 50, 34, 44, 32, 58, 34, 108, 105, 116, 116, 108,
      101, 34, 125, 44, 32, 34, 115, 111, 117, 114, 99, 101, 34, 58, 32, 34, 102, 111, 111, 124,
      98, 97, 114, 34, 125>>
  end
end
