defmodule Gradient.TestHelpers do
  alias Gradient.Types, as: T

  @examples_path "test/examples"
  @examples_build_path "test/examples/_build"

  @spec load(String.t()) :: T.forms()
  def load(beam_file) do
    beam_file = String.to_charlist(Path.join(@examples_build_path, beam_file))

    {:ok, {_, [abstract_code: {:raw_abstract_v1, ast}]}} =
      :beam_lib.chunks(beam_file, [:abstract_code])

    ast
  end

  @spec load(String.t(), String.t()) :: {T.tokens(), T.forms()}
  def load(beam_file, ex_file) do
    beam_file = String.to_charlist(Path.join(@examples_build_path, beam_file))
    ex_file = Path.join(@examples_path, ex_file)

    {:ok, {_, [abstract_code: {:raw_abstract_v1, ast}]}} =
      :beam_lib.chunks(beam_file, [:abstract_code])

    ast = replace_file_path(ast, ex_file)

    [_ | _] = tokens = Gradient.ElixirFileUtils.load_tokens(ast)

    {tokens, ast}
  end

  def load_tokens(path) do
    with {:ok, code} <- File.read(path),
         {:ok, tokens} <- :elixir.string_to_tokens(String.to_charlist(code), 1, 1, path, []) do
      tokens
    end
  end

  @spec example_data() :: {T.tokens(), T.forms()}
  def example_data() do
    beam_path = Path.join(@examples_build_path, "Elixir.SimpleApp.beam") |> String.to_charlist()
    file_path = Path.join(@examples_path, "simple_app.ex")

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
    file_path = Path.join(@examples_path, "conditional/cond.ex")

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
    file_path = Path.join(@examples_path, "string_example.ex")

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
