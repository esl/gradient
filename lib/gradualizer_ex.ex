defmodule GradualizerEx do
  @moduledoc """
  Documentation for `GradualizerEx`.
  """

  def type_check_file(file, opts \\ elixir_opts()) do
    :gradualizer.type_check_file(file, opts)
  end

  def type_check_files(files, opts \\ elixir_opts()) do
    :gradualizer.type_check_files(files, opts)
  end

  def type_check_module(module, opts \\ elixir_opts()) do
    :gradualizer.type_check_module(module, opts)
  end

  def elixir_opts() do
    [gradualizer_fmt: GradualizerEx.ElixirFmt]
  end

  def string_to_quoted(module) do
    File.read!(:code.which(module))
    |> :beam_lib.chunks([:abstract_code])
  end
end
