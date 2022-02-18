defmodule Gradient.TypeData do
  @spec all_pp_test_data() :: [{name :: String.t(), type :: tuple(), expected :: String.t()}]
  def all_pp_test_data() do
    [
      value_test_data(),
      builtin_types_test_data(),
      op_types_test_data(),
      fun_types_test_data(),
      map_types_test_data(),
      tuple_types_test_data(),
      other_types_test_data()
    ]
    |> List.flatten()
  end

  def value_test_data() do
    [
      {"integer value", {:integer, 0, 12}, "12"},
      {"atom value", {:atom, 0, :ok}, ~s(:"ok")},
      {"boolean false", {:atom, 0, false}, "false"},
      {"boolean true", {:atom, 0, true}, "true"},
      {"nil", {:atom, 0, nil}, "nil"}
    ]
  end

  def builtin_types_test_data() do
    [
      {"integer type", {:type, 0, :integer, []}, "integer()"},
      {"float type", {:type, 0, :float, []}, "float()"},
      {"atom type", {:type, 0, :atom, []}, "atom()"},
      {"boolean type", {:type, 0, :boolean, []}, "boolean()"},
      {"binary type", {:type, 0, :binary, []}, "binary()"},
      {"range type", {:type, 0, :range, [{:integer, 0, 1}, {:integer, 0, 10}]}, "1..10"},
      {"list type", {:type, 0, :list, []}, "list()"},
      {"nonempty_list type", {:type, 0, :nonempty_list, []}, "nonempty_list()"},
      {"nil() or []", {:type, 0, nil, []}, "[]"},
      {"type with args", {:type, 0, :list, [{:type, 0, :integer, []}]}, "list(integer())"}
    ]
  end

  def op_types_test_data() do
    [
      {"binary operator", {:op, 0, :+, {:integer, 0, 1}, {:integer, 0, 2}}, "1 + 2"},
      {"unary operator", {:op, 0, :not, {:var, 0, :status}}, "not status"}
    ]
  end

  def fun_types_test_data() do
    [
      {"any fun type", {:type, 0, :fun, []}, "fun()"},
      {"fun with any args returning a specific type",
       {:type, 0, :fun, [{:type, 0, :any}, {:atom, 0, :ok}]}, ~s((... -> :"ok"\))},
      {"fun with specific arg types returning a specific type",
       {:type, 0, :fun, [{:type, 0, :product, [{:type, 0, :atom, []}]}, {:type, 0, :atom, []}]},
       "(atom() -> atom())"}
    ]
  end

  def map_types_test_data() do
    [
      {"any map type", {:type, 0, :map, :any}, "map()"},
      {"complex map type",
       {:type, 0, :map,
        [
          {:type, 0, :map_field_assoc, [{:atom, 0, :value_a}, {:integer, 0, 5}]},
          {:type, 0, :map_field_exact, [{:atom, 0, :value_b}, {:atom, 0, :neo}]}
        ]}, ~s(%{optional(:"value_a"\) => 5, required(:"value_b"\) => :"neo"})}
    ]
  end

  def tuple_types_test_data() do
    [
      {"any tuple type", {:type, 0, :tuple, :any}, "tuple()"},
      {"tuple {:ok, 8}", {:type, 0, :tuple, [{:atom, 0, :ok}, {:integer, 0, 8}]}, ~s({:"ok", 8})}
    ]
  end

  def other_types_test_data() do
    [
      {"var type", {:var, 0, :a}, "a"},
      {"anotated type", {:ann_type, 0, [{:var, 0, :name}, {:type, 0, :integer, []}]},
       "name :: integer()"},
      {"remote type without args",
       {:remote_type, 0, [{:atom, 0, MyModule}, {:atom, 0, :my_fun}, []]}, "MyModule.my_fun()"},
      {"remote type with args",
       {:remote_type, 0, [{:atom, 0, MyModule}, {:atom, 0, :my_fun}, [{:type, 0, :integer, []}]]},
       "MyModule.my_fun(integer())"},
      {"user type", {:user_type, 0, :my_type, [{:type, 0, :atom, []}]}, "my_type(atom())"}
    ]
  end
end
