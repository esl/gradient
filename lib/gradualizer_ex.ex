defmodule GradualizerEx do
  @moduledoc """
  Documentation for `GradualizerEx`.
  """

  alias GradualizerEx.ElixirFileUtils
  alias GradualizerEx.ElixirFmt

  require Logger

  @spec type_check_file(String.t(), Keyword.t()) :: :ok | :error
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
    else
      error ->
        Logger.error("Can't load file - #{inspect(error)}")
        :error
    end
  end
end
