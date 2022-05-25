defmodule GradientTest do
  use ExUnit.Case
  doctest Gradient

  import Gradient.TestHelpers
  import ExUnit.CaptureIO

  test "typecheck erlang beam" do
    # typecheck file with errors
    path = "test/examples/erlang/_build/test_err.beam"
    erl_path = "test/examples/erlang/test_err.erl"
    io_data = capture_io(fn -> assert :error = Gradient.type_check_file(path) end)
    assert String.contains?(io_data, erl_path)
    # typecheck correct file
    capture_io(fn ->
      assert :ok = Gradient.type_check_file("test/examples/erlang/_build/test.beam")
    end)
  end

  test "typecheck elixir beam" do
    # typecheck file with errors
    path = "test/examples/_build/Elixir.WrongRet.beam"
    ex_path = "test/examples/type/wrong_ret.ex"
    io_data = capture_io(fn -> assert :error = Gradient.type_check_file(path) end)
    assert String.contains?(io_data, ex_path)
    # typecheck correct file
    capture_io(fn ->
      assert :ok = Gradient.type_check_file("test/examples/_build/Elixir.Basic.beam")
    end)
  end
end
