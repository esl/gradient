defmodule Gradient.ElixirFileUtils do
  @moduledoc """
  Module used to load beam files generated from Elixir.
  """

  alias Gradient.Types

  @type path() :: :file.filename() | String.t()

  @type abstract_forms() :: [:erl_parse.abstract_form() | :erl_parse.form_info()]

  @type parsed_file_error() ::
          {:file_not_found, path()}
          | {:file_open_error, {:file.posix() | :badarg | :system_limit, path()}}
          | {:forms_not_found, path()}
          | {:forms_error, reason :: any()}

  @doc """
  Accepts a filename or the beam code as a binary
  """
  @spec get_forms_from_beam(path()) ::
          {:ok, abstract_forms()} | parsed_file_error()
  def get_forms_from_beam(path) when is_binary(path),
    do: get_forms_from_beam(String.to_charlist(path))

  def get_forms_from_beam(path) do
    case :beam_lib.chunks(path, [:abstract_code]) do
      {:ok, {_module, [{:abstract_code, {:raw_abstract_v1, forms}}]}} ->
        {:ok, forms}

      {:ok, {_module, [{:abstract_code, :no_abstract_code}]}} ->
        {:forms_not_found, path}

      {:error, :beam_lib, {:file_error, _, :enoent}} ->
        {:file_not_found, path}

      {:error, :beam_lib, {:file_error, _, reason}} ->
        {:file_open_error, {reason, path}}

      {:error, :beam_lib, reason} ->
        {:forms_error, reason}
    end
  end

  @spec load_tokens([:erl_parse.abstract_form()]) :: Types.tokens()
  def load_tokens(forms) do
    with [{:attribute, _, :file, {path, _}} | _] <- forms,
         path <- to_string(path),
         {:ok, code} <- File.read(path),
         {:ok, tokens} <- :elixir.string_to_tokens(String.to_charlist(code), 1, 1, path, []) do
      tokens
    else
      error ->
        IO.puts("Cannot load tokens: #{inspect(error)}")
        []
    end
  end
end
