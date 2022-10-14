defmodule Gradient.CLITest do
  use ExUnit.Case

  @tag :requires_asdf
  test "--path-add option" do
    {_, code} = System.cmd("./gradient", ["test/examples/1.12/range_step.ex"])

    assert 0 == code
  end
end
