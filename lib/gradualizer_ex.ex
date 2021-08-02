defmodule GradualizerEx do
  @moduledoc """
  Documentation for `GradualizerEx`.
  """

  alias GradualizerEx.ElixirFileUtils
  alias GradualizerEx.ElixirFmt

  def type_check_file(file, opts \\ []) do
    opts = Keyword.put(opts, :return_errors, true)

    with {:ok, forms} <- ElixirFileUtils.get_forms_from_beam(file) do
      errors = :gradualizer.type_check_forms(forms, opts)
      opts = Keyword.put(opts, :forms, forms)
      ElixirFmt.print_errors(errors, opts)
      :ok
    end
  end

end
