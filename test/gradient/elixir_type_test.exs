defmodule Gradient.ElixirTypeTest do
  use ExUnit.Case
  doctest Gradient.ElixirType

  alias Gradient.ElixirType

  test "pp integer()" do
    type = {:integer, 0, 12}
    expected = "12"
    actual = ElixirType.pretty_print(type)
    assert expected == actual
  end

  test "pp atom()" do
    type = {:atom, 0, :ok}
    expected = ":ok"
    actual = ElixirType.pretty_print(type)
    assert expected == actual
  end

  test "pp nil()" do
    type = {:atom, 0, nil}
    expected = "nil"
    actual = ElixirType.pretty_print(type)
    assert expected == actual
  end

  test "pp false boolean()" do
    type = {:atom, 0, false}
    expected = "false"
    actual = ElixirType.pretty_print(type)
    assert expected == actual
  end

  test "pp true boolean()" do
    type = {:atom, 0, true}
    expected = "true"
    actual = ElixirType.pretty_print(type)
    assert expected == actual
  end

  test "pp binary()" do
    type = {:type, 0, :binary, []}
    expected = "binary()"
    actual = ElixirType.pretty_print(type)
    assert expected == actual
  end
end
