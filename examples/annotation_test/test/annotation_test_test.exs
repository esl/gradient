defmodule AnnotationTestTest do
  use ExUnit.Case
  doctest AnnotationTest

  test "greets the world" do
    assert AnnotationTest.hello() == :world
  end
end
