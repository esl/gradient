defmodule GradualizerEx do
  @moduledoc """
  Documentation for `GradualizerEx`.
  """

  alias GradualizerEx.ElixirFileUtils
  alias GradualizerEx.ElixirFmt

  @spec type_check_file(String.t(), :gradualizer.options()) :: :ok | :error
  def type_check_file(file, opts \\ []) do
    opts = Keyword.put(opts, :return_errors, true)

    with {:ok, forms} <- ElixirFileUtils.get_forms_from_beam(file) do
      case :gradualizer.type_check_forms(forms, opts) do
        [] ->
          :ok

        errors ->
          opts = Keyword.put(opts, :forms, forms)
          ElixirFmt.print_errors(errors, opts)
          :error
      end
    end
  end
end
