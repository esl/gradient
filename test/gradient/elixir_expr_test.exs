defmodule Gradient.ElixirExprTest do
  use ExUnit.Case
  doctest Gradient.ElixirExpr

  alias Gradient.ElixirExpr
  alias Gradient.ExprData

  require Gradient.Debug
  import Gradient.Debug, only: [elixir_to_ast: 1]

  describe "simple pretty print" do
    for {name, type, expected} <- ExprData.all_basic_pp_test_data() do
      test "#{name}" do
        type = unquote(Macro.escape(type))
        assert unquote(expected) == ElixirExpr.pp_expr(type)
      end
    end
  end

  test "pretty print expr formatted" do
    actual =
      elixir_to_ast do
        case {:ok, 13} do
          {:ok, v} -> v
          _err -> :error
        end
      end
      |> ElixirExpr.pp_expr_format()
      |> Enum.join("")

    assert "case {:ok, 13} do\n  {:ok, v} -> v\n  _err -> :error\nend" == actual
  end

  describe "complex pretty print" do
    test "try guard" do
      actual =
        elixir_to_ast do
          try do
            throw("good")
            :ok
          rescue
            e in RuntimeError ->
              11
              e
          else
            v when v == :ok ->
              :ok

            v ->
              :nok
          catch
            val when is_integer(val) ->
              val

            _ ->
              0
          end
        end
        |> ElixirExpr.pp_expr()

      assert "try do throw \"good\"; :ok; else v when v == :ok -> :ok; v -> :nok; catch :error, %RuntimeError{} = e -> 11; e; :throw, val -> val; :throw, _ -> 0 end" ==
               actual
    end

    test "case guard" do
      actual =
        elixir_to_ast do
          case {:ok, 10} do
            {:ok, v} when (v > 0 and v > 1) or v < -1 ->
              :ok

            t when is_tuple(t) ->
              :nok

            _ ->
              :err
          end
        end
        |> ElixirExpr.pp_expr()

      assert "case {:ok, 10} do {:ok, v} when v > 0 and v > 1 or v < - 1 -> :ok; t when :erlang.is_tuple(t) -> :nok; _ -> :err end" ==
               actual
    end

    test "case" do
      actual =
        elixir_to_ast do
          case {:ok, 13} do
            {:ok, v} -> v
            _err -> :error
          end
        end
        |> ElixirExpr.pp_expr()

      assert "case {:ok, 13} do {:ok, v} -> v; _err -> :error end" == actual
    end

    test "if" do
      actual =
        elixir_to_ast do
          if :math.floor(1.9) == 1.0 do
            :ok
          else
            :error
          end
        end
        |> ElixirExpr.pp_expr()

      assert "if :math.floor(1.9) == 1.0 do :ok else :error end" == actual
    end

    test "unless" do
      actual =
        elixir_to_ast do
          unless :math.floor(1.9) == 1.0 do
            :ok
          else
            :error
          end
        end
        |> ElixirExpr.pp_expr()

      assert "if :math.floor(1.9) == 1.0 do :error else :ok end" == actual
    end

    test "cond" do
      actual =
        elixir_to_ast do
          cond do
            true == false ->
              :ok

            :math.floor(1.9) == 1.0 ->
              :ok

            true ->
              :error
          end
        end
        |> ElixirExpr.pp_expr()

      assert "cond do true == false -> :ok; :math.floor(1.9) == 1.0 -> :ok; true -> :error end" ==
               actual
    end

    test "try with rescue and catch" do
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

      result = ElixirExpr.pp_expr(try_expr)

      assert "try do if true do throw \"good\" else raise \"oops\" end;" <>
               " catch :error, %RuntimeError{} = e -> 11; e; :throw, val -> 12; val end" == result
    end
  end
end
