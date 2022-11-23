defmodule Gradient.ElixirFileUtils do
  @moduledoc """
  Module used to load beam files generated from Elixir.
  """

  alias Gradient.Types

  @type path() :: :file.filename() | binary()

  @type abstract_forms() :: [:erl_parse.abstract_form() | :erl_parse.form_info()]

  @type parsed_file_error() ::
          {:file_not_found, path()}
          | {:file_open_error, {:file.posix() | :badarg | :system_limit, path()}}
          | {:forms_not_found, path()}
          | {:forms_error, reason :: any()}

  @doc """
  Accepts a filename or the beam code as a binary
  """
  @spec get_forms_from_beam(path()) ::
          {:ok, abstract_forms()} | parsed_file_error()
  def get_forms_from_beam(path) do
    case :beam_lib.chunks(path, [:abstract_code]) do
      {:ok, {_module, [{:abstract_code, {:raw_abstract_v1, forms}}]}} ->
        {:ok, forms}

      {:ok, {_module, [{:abstract_code, :no_abstract_code}]}} ->
        {:forms_not_found, path}

      {:error, :beam_lib, {:file_error, _, :enoent}} ->
        {:file_not_found, path}

      {:error, :beam_lib, {:file_error, _, reason}} ->
        {:file_open_error, {reason, path}}

      {:error, :beam_lib, reason} ->
        {:forms_error, reason}
    end
  end

  @spec get_forms_from_ex(binary(), String.t()) ::
          {:ok, list(abstract_forms())} | parsed_file_error()
  def get_forms_from_ex(path, module \\ "all_modules") do
    # For compiling many files concurrently, see Kernel.ParallelCompiler.compile/2.
    if File.exists?(path) do
      forms =
        path
        |> Code.compile_file()
        |> Enum.reduce([], fn {required_module_name, binary}, acc ->
          ensure_module_loaded_into_gradualizer(binary)

          if module != "all_modules" do
            string_module_name = Atom.to_string(required_module_name)

            if string_module_name == "Elixir." <> module do
              {:ok, forms} = get_forms_from_beam(binary)
              [forms | acc]
            else
              acc
            end
          else
            {:ok, forms} = get_forms_from_beam(binary)
            [forms | acc]
          end
        end)

      {:ok, forms}
    else
      {:file_not_found, path}
    end
  end

  def get_forms(path, module \\ "all_modules") do
    case Path.extname(path) do
      ".beam" ->
        path
        |> to_charlist()
        |> get_forms_from_beam()
        |> case do
          {:ok, forms} -> {:ok, [forms]}
          error -> error
        end

      ".ex" ->
        get_forms_from_ex(path, module)

      _ ->
        which =
          [path]
          |> Module.concat()
          |> :code.which()

        case which do
          filename when is_list(filename) ->
            get_forms_from_beam(filename)
            |> case do
              {:ok, forms} -> {:ok, [forms]}
              error -> error
            end

          other ->
            raise "Could not get forms for path #{inspect(path)}, got #{inspect(other)}"
        end
    end
  end

  @spec load_tokens([:erl_parse.abstract_form()]) :: Types.tokens()
  def load_tokens(forms) do
    case forms do
      [{:attribute, _, :file, {path, _}} | _] ->
        load_tokens_at_path(path)

      _ ->
        IO.puts("Error finding file attribute from forms: #{inspect(forms)}")
        []
    end
  end

  defp load_tokens_at_path(path) do
    with path <- to_string(path),
         {:ok, code} <- File.read(path),
         {:ok, tokens} <- :elixir.string_to_tokens(String.to_charlist(code), 1, 1, path, []) do
      tokens
    else
      error ->
        IO.puts("Error loading tokens from file at path #{inspect(path)}: #{inspect(error)}")
        []
    end
  end

  defp ensure_module_loaded_into_gradualizer(binary) do
    {path, _} = System.cmd("mktemp", [])
    sanitized_path = path |> String.trim() |> Kernel.<>(".beam")

    :ok = :file.write_file(to_charlist(sanitized_path), binary)

    :ok = :gradualizer_db.import_beam_files([to_charlist(sanitized_path)])
  end
end
