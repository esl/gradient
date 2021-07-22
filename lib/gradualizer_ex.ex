defmodule GradualizerEx do
  @moduledoc """
  Documentation for `GradualizerEx`.
  """

  def type_check_file(file, opts \\ []) do
    :gradualizer.type_check_file(file, opts)
  end

  def type_check_files(files) do
    :gradualizer.type_check_files(files)
  end

  def type_check_module(module, opts \\ []) do
    :gradualizer.type_check_module(module, opts)
  end
end
