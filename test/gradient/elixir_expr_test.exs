defmodule Gradient.ElixirExprTest do
  use ExUnit.Case
  doctest Gradient.ElixirExpr

  alias Gradient.ElixirExpr

  test "try expr" do
    try_expr =
      {:try, 3,
       [
         {:case, 4, {:atom, 4, true},
          [
            {:clause, [generated: true, location: 4], [{:atom, 0, false}], [],
             [
               {:call, 7, {:remote, 7, {:atom, 7, :erlang}, {:atom, 7, :error}},
                [
                  {:call, 7, {:remote, 7, {:atom, 7, RuntimeError}, {:atom, 7, :exception}},
                   [
                     {:bin, 7,
                      [
                        {:bin_element, 7, {:string, 7, 'oops'}, :default, :default}
                      ]}
                   ]}
                ]}
             ]},
            {:clause, [generated: true, location: 4], [{:atom, 0, true}], [],
             [
               {:call, 5, {:remote, 5, {:atom, 5, :erlang}, {:atom, 5, :throw}},
                [
                  {:bin, 5, [{:bin_element, 5, {:string, 5, 'good'}, :default, :default}]}
                ]}
             ]}
          ]}
       ], [],
       [
         {:clause, 10,
          [
            {:tuple, 10,
             [
               {:atom, 10, :error},
               {:var, 10, :_@1},
               {:var, 10, :___STACKTRACE__@1}
             ]}
          ],
          [
            [
              {:op, 10, :andalso,
               {:op, 10, :==,
                {:call, 10, {:remote, 10, {:atom, 10, :erlang}, {:atom, 10, :map_get}},
                 [{:atom, 10, :__struct__}, {:var, 10, :_@1}]}, {:atom, 10, RuntimeError}},
               {:call, 10, {:remote, 10, {:atom, 10, :erlang}, {:atom, 10, :map_get}},
                [{:atom, 10, :__exception__}, {:var, 10, :_@1}]}}
            ]
          ],
          [
            {:match, 10, {:var, 10, :_e@1}, {:var, 10, :_@1}},
            {:integer, 11, 11},
            {:var, 12, :_e@1}
          ]},
         {:clause, 14,
          [
            {:tuple, 14,
             [
               {:atom, 14, :throw},
               {:var, 14, :_val@1},
               {:var, 14, :___STACKTRACE__@1}
             ]}
          ], [], [{:integer, 15, 12}, {:var, 16, :_val@1}]}
       ], []}

    result = ElixirExpr.pretty_print(try_expr)

    assert "try do case :true do :false -> erlang.error(RuntimeError.exception(\"oops\")); " <>
             ":true -> erlang.throw(\"good\") end; catch :error, %:Elixir.RuntimeError{} = _e@1 -> " <>
             "11; _e@1; :throw, _val@1 -> 12; _val@1 end" == result
  end
end
