defmodule TypedGenServerTest do
  use ExUnit.Case
  doctest TypedGenServer

  test "greets the world" do
    assert TypedGenServer.hello() == :world
  end
end
