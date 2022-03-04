defmodule Gradient.ElixirCheckerTest do
  use ExUnit.Case
  doctest Gradient.ElixirChecker

  alias Gradient.ElixirChecker

  import Gradient.TestHelpers

  test "checker options" do
    ast = load("Elixir.SpecWrongName.beam")

    assert [] = ElixirChecker.check(ast, ex_check: false)
    assert [] != ElixirChecker.check(ast, ex_check: true)
  end

  test "all specs are correct" do
    ast = load("Elixir.CorrectSpec.beam")

    assert [] = ElixirChecker.check(ast, ex_check: true)
  end

  test "spec name doesn't match the function name" do
    ast = load("Elixir.SpecWrongName.beam")

    assert [
             {_, {:spec_error, :wrong_spec_name, 11, :last_two, 1}},
             {_, {:spec_error, :wrong_spec_name, 5, :convert, 1}}
           ] = ElixirChecker.check(ast, [])
  end

  test "more than one spec per function clause is not allowed" do
    ast = load("Elixir.SpecAfterSpec.beam")

    assert [
             {_, {:spec_error, :spec_after_spec, 3, :convert_a, 1}}
           ] = ElixirChecker.check(ast, [])
  end
end
