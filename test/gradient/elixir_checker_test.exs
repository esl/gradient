defmodule Gradient.ElixirCheckerTest do
  use ExUnit.Case
  doctest Gradient.ElixirChecker

  alias Gradient.ElixirChecker

  import Gradient.TestHelpers

  test "checker options" do
    ast = load("Elixir.SpecWrongName.beam")

    assert [] = ElixirChecker.check(ast, env([], ex_check: false))
    assert [] != ElixirChecker.check(ast, env([], ex_check: true))
  end

  test "all specs are correct" do
    ast = load("Elixir.CorrectSpec.beam")

    assert [] = ElixirChecker.check(ast, env())
  end

  test "specs over default args are correct" do
    ast = load("Elixir.SpecDefaultArgs.beam")

    assert [] = ElixirChecker.check(ast, env())
  end

  test "spec arity doesn't match the function arity" do
    ast = load("Elixir.SpecWrongArgsArity.beam")

    assert [{_, {:spec_error, :wrong_spec_name, 2, :foo, 3}}] = ElixirChecker.check(ast, env())
  end

  test "spec name doesn't match the function name" do
    ast = load("Elixir.SpecWrongName.beam")

    assert [
             {_, {:spec_error, :wrong_spec_name, 5, :convert, 1}},
             {_, {:spec_error, :wrong_spec_name, 11, :last_two, 1}}
           ] = ElixirChecker.check(ast, env())
  end

  test "mixing specs names is not allowed" do
    ast = load("Elixir.SpecMixed.beam")

    assert [
             {_, {:spec_error, :mixed_specs, 3, :encode, 1}},
             {_, {:spec_error, :wrong_spec_name, 3, :encode, 1}}
           ] = ElixirChecker.check(ast, env())
  end

  test "spec defined in a __using__ macro with tokens" do
    {tokens, ast} = load("Elixir.SpecInMacro.beam", "spec_in_macro.ex")

    assert [] = ElixirChecker.check(ast, env(tokens))
  end

  test "spec defined in a __using__ macro without tokens" do
    ast = load("Elixir.SpecInMacro.beam")

    assert [] = ElixirChecker.check(ast, env())
  end

  defp env(tokens \\ [], opts \\ []) do
    [{:env, Gradient.build_env(tokens)} | opts]
  end
end
