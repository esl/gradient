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

  # def type_check_file(file, opts \\ elixir_opts()) do
  # :gradualizer.type_check_file(file, opts)
  # end

  def type_check_files(files, opts \\ elixir_opts()) do
    :gradualizer.type_check_files(files, opts)
  end

  def type_check_module(module, opts \\ elixir_opts()) do
    :gradualizer.type_check_module(module, opts)
  end

  def elixir_opts() do
    [
      gradualizer_fmt: GradualizerEx.ElixirFmt,
      gradualizer_file_loader: GradualizerEx.ElixirFileUtils
    ]
  end

  def string_to_quoted(module) do
    File.read!(:code.which(module))
    |> :beam_lib.chunks([:abstract_code])
  end
end
