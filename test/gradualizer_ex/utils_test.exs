defmodule GradualizerEx.UtilsTest do
  use ExUnit.Case

  alias GradualizerEx.Utils

  @examples_path "test/examples"

  test "drop_tokens_while" do
    tokens = example_tokens()

    matcher = fn
      {:atom, _, :ok} -> false
      _ -> true
    end

    assert [] =
             Utils.drop_tokens_while(
               tokens,
               matcher,
               5
             )

    refute [] ==
             Utils.drop_tokens_while(
               tokens,
               matcher,
               6
             )

    refute [] ==
             Utils.drop_tokens_while(
               tokens,
               matcher,
               -1
             )
  end

  def example_tokens() do
    file_path = @examples_path <> "/conditional/cond.ex"

    code =
      File.read!(file_path)
      |> String.to_charlist()

    {:ok, tokens} =
      code
      |> :elixir.string_to_tokens(1, 1, file_path, [])

    tokens
  end
end
