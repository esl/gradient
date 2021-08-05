defmodule GradualizerEx.ElixirFileUtils do
  @moduledoc """
  Module used to load beam files generated from Elixir.
  """

  alias GradualizerEx.SpecifyErlAst

  @doc """
  Accepts a filename or the beam code as a binary
  """
  @spec get_forms_from_beam(:file.filename() | String.t()) ::
          {:ok, [SpecifyErlAst.form()]} | {:error, any()}
  def get_forms_from_beam(path) when is_binary(path),
    do: get_forms_from_beam(String.to_charlist(path))

  def get_forms_from_beam(path) do
    case :beam_lib.chunks(path, [:abstract_code]) do
      {:ok, {_module, [{:abstract_code, {:raw_abstract_v1, forms}}]}} ->
        {:ok, forms |> SpecifyErlAst.specify()}

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
end
