defmodule GradualizerEx.TestHelpers do
  alias GradualizerEx.Types, as: T

  @examples_path "test/examples"

  @spec load(String.t(), String.t()) :: {T.tokens(), T.forms()}
  def load(beam_file, ex_file) do
    beam_file = String.to_charlist(@examples_path <> beam_file)
    ex_file = @examples_path <> ex_file

    code =
      File.read!(ex_file)
      |> String.to_charlist()

    {:ok, tokens} =
      code
      |> :elixir.string_to_tokens(1, 1, ex_file, [])

    {:ok, {_, [abstract_code: {:raw_abstract_v1, ast}]}} =
      :beam_lib.chunks(beam_file, [:abstract_code])

    ast = replace_file_path(ast, ex_file)
    {tokens, ast}
  end

  @spec example_data() :: {T.tokens(), T.forms()}
  def example_data() do
    beam_path = (@examples_path <> "/Elixir.SimpleApp.beam") |> String.to_charlist()
    file_path = @examples_path <> "/simple_app.ex"

    code =
      File.read!(file_path)
      |> String.to_charlist()

    {:ok, tokens} =
      code
      |> :elixir.string_to_tokens(1, 1, file_path, [])

    {:ok, {SimpleApp, [abstract_code: {:raw_abstract_v1, ast}]}} =
      :beam_lib.chunks(beam_path, [:abstract_code])

    ast = replace_file_path(ast, file_path)
    {tokens, ast}
  end

  @spec example_tokens() :: T.tokens()
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

  @spec example_string_tokens() :: T.tokens()
  def example_string_tokens() do
    file_path = @examples_path <> "/string_example.ex"

    code =
      File.read!(file_path)
      |> String.to_charlist()

    {:ok, tokens} =
      code
      |> :elixir.string_to_tokens(1, 1, file_path, [])

    tokens
  end

  defp replace_file_path([_ | forms], path) do
    path = String.to_charlist(path)
    [{:attribute, 1, :file, {path, 1}} | forms]
  end
end
