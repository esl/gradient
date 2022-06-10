defmodule Gradient.TypeAnnotationTest do
  use ExUnit.Case

  import Gradient.TestHelpers
  import ExUnit.CaptureIO

  @no_color [ex_colors: [use_colors: false]]

  test "no annotation leads to check failure" do
    path = "test/examples/_build/Elixir.Annotations.ShouldFail.NoAnno.beam"
    io_data = capture_io(fn ->
      assert :error = Gradient.type_check_file(path, @no_color)
    end)
    assert String.contains?(io_data, "expected to have type nonempty_list")
  end

  test "invalid annotation leads to check failure" do
    path = "test/examples/_build/Elixir.Annotations.ShouldFail.BadAnno.beam"
    io_data = capture_io(fn ->
      assert :error = Gradient.type_check_file(path, @no_color)
    end)
    assert String.contains?(io_data, "expected to have type float")
  end

  test "valid annotation ensures successful check" do
    path = "test/examples/_build/Elixir.Annotations.ShouldPass.beam"
    io_data = capture_io(fn ->
      assert :ok = Gradient.type_check_file(path)
    end)
  end
end
