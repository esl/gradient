defmodule Gradient.UtilsTest do
  use ExUnit.Case

  alias Gradient.Utils

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
               5,
               matcher
             )

    refute [] ==
             Utils.drop_tokens_while(
               tokens,
               6,
               matcher
             )

    refute [] ==
             Utils.drop_tokens_while(
               tokens,
               matcher
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
