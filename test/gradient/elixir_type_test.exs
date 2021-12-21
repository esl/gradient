defmodule Gradient.ElixirTypeTest do
  use ExUnit.Case
  doctest Gradient.ElixirType

  alias Gradient.ElixirType
  alias Gradient.TypeData

  describe "pretty print" do
    for {name, type, expected} <- TypeData.all_pp_test_data() do
      test "#{name}" do
        type = unquote(Macro.escape(type))
        assert unquote(expected) == ElixirType.pretty_print(type)
      end
    end
  end
end
