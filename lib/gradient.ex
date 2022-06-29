defmodule Gradient do
  @moduledoc """
  Documentation for `Gradient`.
  """

  alias Gradient.ElixirFileUtils
  alias Gradient.ElixirFmt
  alias Gradient.Error
  alias Gradient.AstSpecifier
  alias Gradient.ElixirChecker

  require Logger

  @typedoc """
  - `app_path` - Path to the app that contains file with code (for umbrella apps).
  - `code_path` - Path to a file with code (e.g. when beam was compiled without project).
  - `no_gradualizer_check` - Skip Gradualizer checks if true.
  - `no_ex_check` - Skip Elixir checks if true.
  - `no_specify` - Skip AST specifying if true.
  """
  @type options() :: [
          app_path: String.t(),
          code_path: String.t(),
          no_gradualizer_check: boolean(),
          no_ex_check: boolean(),
          no_specify: boolean(),
          ignores: [Error.ignore()]
        ]

  @type error() :: :gradualizer_check_nok | :cannot_load_file | tuple()

  @doc """
  Type-checks file in `path` with provided `opts`, and prints the result.
  """
  @spec type_check_file(charlist() | String.t(), options()) :: :ok | {:error, [error(), ...]}
  def type_check_file(path, opts \\ []) do
    opts = Keyword.put(opts, :return_errors, true)

    with {:ok, forms} <- ElixirFileUtils.get_forms(path),
         {:elixir, _} <- wrap_language_name(forms) do
      forms = maybe_specify_forms(forms, opts)

      case maybe_gradient_check(forms, opts) ++ maybe_gradualizer_check(forms, opts) do
        [] ->
          :ok

        errors ->
          opts = Keyword.put(opts, :forms, forms)

          case Error.reject_ignored_errors(errors, opts) do
            [] ->
              :ok

            [_ | _] = filtered_errors ->
              ElixirFmt.print_errors(filtered_errors, opts)
              {:error, filtered_errors}
          end
      end
    else
      {:erlang, forms} ->
        opts = Keyword.put(opts, :return_errors, false)

        case maybe_gradualizer_check(forms, opts) do
          :nok -> {:error, [:gradualizer_check_nok]}
          _ -> :ok
        end

      error ->
        Logger.error("Can't load file - #{inspect(error)}")
        {:error, [:cannot_load_file]}
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
      forms
      |> put_code_path(opts)
      |> AstSpecifier.specify()
    else
      forms
    end
  end

  defp wrap_language_name([{:attribute, _, :file, {file_name, _}} | _] = forms) do
    if :string.str(file_name, '.erl') > 0 do
      {:erlang, forms}
    else
      {:elixir, forms}
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
