defmodule Gradient.CLITest do
  use ExUnit.Case

  test "--path-add option" do
    {_, code} =
      System.cmd("sh", ["-c", "./gradient test/examples/1.12/range_step.ex"]) |> IO.inspect()

    # {_, code} = System.cmd("./gradient", ["test/examples/1.12/range_step.ex"])

    assert 0 == code
  end
end
