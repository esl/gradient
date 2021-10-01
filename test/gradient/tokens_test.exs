defmodule GradualizerEx.TokensTest do
  use ExUnit.Case
  doctest GradualizerEx.Tokens

  alias GradualizerEx.Tokens

  import GradualizerEx.TestHelpers

  test "drop_tokens_while" do
    tokens = example_tokens()

    matcher = fn
      {:atom, _, :ok} -> false
      _ -> true
    end

    assert [] =
             Tokens.drop_tokens_while(
               tokens,
               5,
               matcher
             )

    refute [] ==
             Tokens.drop_tokens_while(
               tokens,
               6,
               matcher
             )

    refute [] ==
             Tokens.drop_tokens_while(
               tokens,
               matcher
             )
  end

  test "get_list_from_tokens" do
    tokens = example_string_tokens()
    ts = Tokens.drop_tokens_to_line(tokens, 4)
    opts = [end_line: -1]
    assert {:charlist, _} = Tokens.get_list(ts, opts)

    ts = Tokens.drop_tokens_to_line(ts, 6)
    assert {:list, _} = Tokens.get_list(ts, opts)
  end

  describe "get_conditional/1" do
    test "case" do
      {tokens, _ast} = load("/conditional/Elixir.Conditional.Case.beam", "/conditional/case.ex")
      tokens = Tokens.drop_tokens_to_line(tokens, 2)
      opts = [end_line: -1]
      assert {:case, _} = Tokens.get_conditional(tokens, 4, opts)

      tokens = Tokens.drop_tokens_to_line(tokens, 9)
      assert {:case, _} = Tokens.get_conditional(tokens, 10, opts)
    end

    test "if" do
      {tokens, _ast} = load("/conditional/Elixir.Conditional.If.beam", "/conditional/if.ex")
      tokens = Tokens.drop_tokens_to_line(tokens, 2)
      opts = [end_line: -1]
      assert {:if, _} = Tokens.get_conditional(tokens, 4, opts)

      tokens = Tokens.drop_tokens_to_line(tokens, 12)
      assert {:if, _} = Tokens.get_conditional(tokens, 13, opts)
    end

    test "unless" do
      {tokens, _ast} =
        load("/conditional/Elixir.Conditional.Unless.beam", "/conditional/unless.ex")

      tokens = Tokens.drop_tokens_to_line(tokens, 2)
      opts = [end_line: -1]
      assert {:unless, _} = Tokens.get_conditional(tokens, 3, opts)
    end

    test "cond" do
      {tokens, _ast} = load("/conditional/Elixir.Conditional.Cond.beam", "/conditional/cond.ex")

      tokens = Tokens.drop_tokens_to_line(tokens, 2)
      opts = [end_line: -1]
      assert {:cond, _} = Tokens.get_conditional(tokens, 4, opts)

      tokens = Tokens.drop_tokens_to_line(tokens, 10)
      assert {:cond, _} = Tokens.get_conditional(tokens, 13, opts)
    end

    test "with" do
      {tokens, _ast} = load("/conditional/Elixir.Conditional.With.beam", "/conditional/with.ex")

      tokens = Tokens.drop_tokens_to_line(tokens, 6)
      opts = [end_line: -1]
      assert {:with, _} = Tokens.get_conditional(tokens, 7, opts)
    end
  end
end
