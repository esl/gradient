defmodule Gradient.CLITest do
  use ExUnit.Case

  @tag :requires_asdf
  test "Gradient escript detects asdf-installed Elixir libs" do
    {_, code} = System.cmd("sh", ["-c", "./gradient test/examples/1.12/range_step.ex"])

    assert 0 == code
  end
end
