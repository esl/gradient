defmodule AppBTest do
  use ExUnit.Case
  doctest AppB

  test "greets the world" do
    assert AppB.hello() == :world
  end
end
