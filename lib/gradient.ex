defmodule Gradient do
  @moduledoc """
  Documentation for `Gradient`.

  Options:
  - `app_path` - Path to the app that contains file with code (for umbrella apps).
  - `code_path` - Path to a file with code (e.g. when beam was compiled without project).
  - `no_gradualizer_check` - Skip Gradualizer checks if true.
  - `no_ex_check` - Skip Elixir checks if true.
  - `no_specify` - Skip AST specifying if true.
  """

  alias Gradient.ElixirFileUtils
  alias Gradient.ElixirFmt
  alias Gradient.AstSpecifier
  alias Gradient.ElixirChecker

  require Logger

  @type options() :: [{:app_path, String.t()}, {:code_path, String.t()}]

  @spec type_check_file(String.t(), options()) :: :ok | :error
  def type_check_file(file, opts \\ []) do
    opts = Keyword.put(opts, :return_errors, true)

    with {:ok, forms} <- ElixirFileUtils.get_forms(file) do
      forms = maybe_specify_forms(forms, opts)

      case maybe_gradient_check(forms, opts) ++ maybe_gradualizer_check(forms, opts) do
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

  defp maybe_gradualizer_check(forms, opts) do
    unless opts[:no_gradualizer_check] do
      try do
        :gradualizer.type_check_forms(forms, opts)
      catch
        err ->
          {:attribute, _, :file, {path, _}} = hd(forms)
          [{path, err}]
      end
    else
      []
    end
  end

  defp maybe_gradient_check(forms, opts) do
    unless opts[:no_ex_check] do
      ElixirChecker.check(forms, opts)
    else
      []
    end
  end

  defp maybe_specify_forms(forms, opts) do
    unless opts[:no_specify] do
      IO.puts("Specifying froms...")

      forms
      |> put_code_path(opts)
      |> AstSpecifier.specify()
    else
      forms
    end
  end

  defp put_code_path(forms, opts) do
    case opts[:code_path] do
      nil ->
        case opts[:app_path] do
          nil ->
            forms

          app_path ->
            {:attribute, anno, :file, {path, line}} = hd(forms)

            [
              {:attribute, anno, :file, {String.to_charlist(app_path) ++ '/' ++ path, line}}
              | tl(forms)
            ]
        end

      path ->
        [{:attribute, 1, :file, {path, 1}} | tl(forms)]
    end
  end
end
