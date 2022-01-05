defmodule Gradient.ExprData do
  def all_basic_pp_test_data() do
    [value_test_data(), list_test_data(), call_test_data(), variable_test_data()]
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
end
