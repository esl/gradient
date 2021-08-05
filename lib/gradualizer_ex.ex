defmodule GradualizerEx do
  @moduledoc """
  Documentation for `GradualizerEx`.

  Options:
  - `code_path` - Path to a file with code.
  """

  alias GradualizerEx.ElixirFileUtils
  alias GradualizerEx.ElixirFmt
  alias GradualizerEx.SpecifyErlAst

  require Logger

  @spec type_check_file(String.t(), Keyword.t()) :: :ok | :error
  def type_check_file(file, opts \\ []) do
    opts = Keyword.put(opts, :return_errors, true)

    with {:ok, forms} <- ElixirFileUtils.get_forms_from_beam(file) do
      forms =
        forms
        |> put_code_path(opts)
        |> SpecifyErlAst.specify()

      case :gradualizer.type_check_forms(forms, opts) do
        [] ->
          :ok

        errors ->
          opts = Keyword.put(opts, :forms, forms)
          ElixirFmt.print_errors(errors, opts)
          :error
      end
    else
      error ->
        Logger.error("Can't load file - #{inspect(error)}")
        :error
    end
  end

  defp put_code_path(forms, opts) do
    case Keyword.fetch(opts, :code_path) do
      {:ok, path} -> [{:attribute, 1, :file, {path, 1}} | tl(forms)]
      _ -> forms
    end
  end
end
