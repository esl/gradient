defmodule AppATest do
  use ExUnit.Case
  doctest AppA

  test "greets the world" do
    assert AppA.hello() == :world
  end
end
