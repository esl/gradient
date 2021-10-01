defmodule Gradient do
  @moduledoc """
  Documentation for `Gradient`.

  Options:
  - `app_path` - Path to the app that contains file with code (for umbrella apps).
  - `code_path` - Path to a file with code (e.g. when beam was compiled without project).
  """

  alias GradualizerEx.ElixirFileUtils
  alias GradualizerEx.ElixirFmt
  alias GradualizerEx.AstSpecifier

  require Logger

  @type options() :: [{:app_path, String.t()}, {:code_path, String.t()}]

  @spec type_check_file(String.t(), options()) :: :ok | :error
  def type_check_file(file, opts \\ []) do
    opts = Keyword.put(opts, :return_errors, true)

    with {:ok, forms} <- ElixirFileUtils.get_forms_from_beam(file) do
      forms =
        forms
        |> put_code_path(opts)
        |> AstSpecifier.specify()

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
      {:ok, path} ->
        [{:attribute, 1, :file, {path, 1}} | tl(forms)]

      :error ->
        case Keyword.fetch(opts, :app_path) do
          {:ok, app_path} ->
            {:attribute, anno, :file, {path, line}} = hd(forms)

            [
              {:attribute, anno, :file, {String.to_charlist(app_path) ++ '/' ++ path, line}}
              | tl(forms)
            ]

          :error ->
            forms
        end
    end
  end
end
