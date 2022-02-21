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
    test "lambda" do
      actual =
        elixir_to_ast do
          fn
            {:ok, v} ->
              v

            {:error, _} ->
              :error
          end
        end
        |> ElixirExpr.pp_expr()

      assert "fn {:ok, v} -> v; {:error, _} -> :error end" == actual
    end

    test "binary comprehension" do
      actual =
        elixir_to_ast do
          pixels = <<213, 45, 132, 64, 76, 32, 76, 0, 0, 234, 32, 15>>
          for <<r::8, g::8, b::8 <- pixels>>, do: {r, g, b}
        end
        |> ElixirExpr.pp_expr()

      assert "pixels = <<213, 45, 132, 64, 76, 32, 76, 0, 0, 234, 32, 15>>; for <<r::8, g::8, b::8 <- pixels >>, do: {r, g, b}" ==
               actual
    end

    test "binary comprehension 2" do
      actual =
        elixir_to_ast do
          for <<one, (_rest::binary-size(3) <- <<1, 2, 3, 4>>)>>, do: one
        end
        |> ElixirExpr.pp_expr()

      assert "for <<one, _rest::binary-size(3) <- <<1, 2, 3, 4>> >>, do: one" == actual
    end

    test "receive" do
      actual =
        elixir_to_ast do
          receive do
            {:hello, msg} -> msg
          end
        end
        |> ElixirExpr.pp_expr()

      assert "receive do {:hello, msg} -> msg end" == actual
    end

    test "receive after" do
      actual =
        elixir_to_ast do
          receive do
            {:hello, msg} -> msg
          after
            1_000 -> "nothing happened"
          end
        end
        |> ElixirExpr.pp_expr()

      assert ~s(receive do {:hello, msg} -> msg after 1000 -> "nothing happened" end) == actual
    end

    test "call pipe" do
      actual =
        elixir_to_ast do
          [1, 2, 3]
          |> Enum.map(fn x -> x + 1 end)
          |> Enum.map(&(&1 + 1))
        end
        |> ElixirExpr.pp_expr()

      assert "Enum.map(Enum.map([1, 2, 3], fn x -> x + 1 end), fn _ -> _ + 1 end)" == actual
    end

    test "with" do
      actual =
        elixir_to_ast do
          map = %{a: 12, b: 0}

          with {:ok, a} <- Map.fetch(map, :a),
               {:ok, b} <- Map.fetch(map, :b) do
            a + b
          else
            :error ->
              0
          end
        end
        |> ElixirExpr.pp_expr()

      assert "map = %{a: 12, b: 0}; case :maps.find(:a, map) do {:ok, a} -> case :maps.find(:b, map) do {:ok, b} -> a + b; _gen -> case _gen do :error -> 0; _gen -> raise {:with_clause, _gen} end end; _gen -> case _gen do :error -> 0; _gen -> raise {:with_clause, _gen} end end" ==
               actual
    end

    test "try reraise" do
      actual =
        elixir_to_ast do
          try do
            raise "ok"
          rescue
            e ->
              IO.puts(Exception.format(:error, e, __STACKTRACE__))
              reraise e, __STACKTRACE__
          end
        end
        |> ElixirExpr.pp_expr()

      assert ~s(try do raise "ok"; catch :error, e -> IO.puts(Exception.format(:error, e, __STACKTRACE__\)\); reraise e, __STACKTRACE__ end) ==
               actual
    end

    test "try rescue without error var" do
      actual =
        elixir_to_ast do
          try do
            raise "oops"
          rescue
            RuntimeError -> "Error!"
          end
        end
        |> ElixirExpr.pp_expr()

      assert ~s(try do raise "oops"; catch :error, %RuntimeError{} = _ -> "Error!" end) ==
               actual
    end

    test "simple rescue try" do
      actual =
        elixir_to_ast do
          try do
            :ok
          rescue
            _ -> :ok
          end
        end
        |> ElixirExpr.pp_expr()

      assert "try do :ok; catch :error, _ -> :ok end" == actual
    end

    test "simple after try" do
      actual =
        elixir_to_ast do
          try do
            :ok
          after
            :ok
          end
        end
        |> ElixirExpr.pp_expr()

      assert "try do :ok; after :ok end" == actual
    end

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
          after
            IO.puts("Cleaning!")
          end
        end
        |> ElixirExpr.pp_expr()

      assert ~s(try do throw "good"; :ok; else v when v == :ok -> :ok; v -> :nok; catch :error, %RuntimeError{} = e -> 11; e; :throw, val -> val; :throw, _ -> 0; after IO.puts("Cleaning!"\) end) ==
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
      actual =
        elixir_to_ast do
          try do
            if true do
              throw("good")
            else
              raise "oops"
            end
          rescue
            e in RuntimeError ->
              11
              e
          catch
            val ->
              12
              val
          end
        end
        |> ElixirExpr.pp_expr()

      assert ~s(try do if true do throw "good" else raise "oops" end;) <>
               ~s( catch :error, %RuntimeError{} = e -> 11; e; :throw, val -> 12; val end) ==
               actual
    end
  end

  test "pp and format complex try expression" do
    {_tokens, ast} =
      Gradient.TestHelpers.load("/Elixir.CallRemoteException.beam", "/call_remote_exception.ex")

    {:function, _, :call, 2, [{:clause, _ann, _args, _guards, [try_expr]}]} =
      Enum.reverse(ast) |> List.first()

    res = ElixirExpr.pp_expr_format(try_expr)

    # FIXME `raise {:badkey, :stack, _gen}` is not correct

    expected = ~s"""
    try do
      :ok
    catch
      :error, %Plug.Conn.WrapperError{} = e ->
        exception =
          Exception.normalize(
            :error,
            case e do
              %{reason: _gen} -> _gen
              _gen when :erlang.is_map(_gen) -> raise {:badkey, :reason, _gen}
              _gen -> _gen.reason()
            end,
            case e do
              %{stack: _gen} -> _gen
              _gen when :erlang.is_map(_gen) -> raise {:badkey, :stack, _gen}
              _gen -> _gen.stack()
            end
          )

        _ =
          Sentry.capture_exception(exception, [
            {:stacktrace,
             case e do
               %{stack: _gen} -> _gen
               _gen when :erlang.is_map(_gen) -> raise {:badkey, :stack, _gen}
               _gen -> _gen.stack()
             end},
            {:event_source, :plug}
          ])

        Plug.Conn.WrapperError.reraise(e)

      :error, e ->
        _ = Sentry.capture_exception(e, [{:stacktrace, __STACKTRACE__}, {:event_source, :plug}])
        :erlang.raise(:error, e, __STACKTRACE__)

      kind, reason ->
        message =
          <<"Uncaught ",
            case kind do
              _gen when :erlang.is_binary(_gen) -> _gen
              _gen -> String.Chars.to_string(_gen)
            end::binary, " - ", Kernel.inspect(reason)::binary>>

        stack = __STACKTRACE__
        _ = Sentry.capture_message(message, [{:stacktrace, stack}, {:event_source, :plug}])
        :erlang.raise(kind, reason, stack)
    end
    """

    assert expected == :erlang.iolist_to_binary(res) <> "\n"
  end
end
