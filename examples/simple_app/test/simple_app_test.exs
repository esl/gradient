defmodule SimpleAppTest do
  use ExUnit.Case
  doctest SimpleApp

  test "greets the world" do
    assert SimpleApp.hello() == :world
  end
end
