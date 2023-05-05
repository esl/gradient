defmodule Gradient.Debug do
  @moduledoc ~S"""
  Helpers for convenient debugging Erlang and Elixir ASTs.
  """

  alias Gradient.ElixirType

  ## TODO: specify elixir_form
  @type elixir_form() :: any()
  @type erlang_form() :: Gradient.Types.form()

  @doc ~S"""
  Translate the Elixir code to the Erlang AST.
  """
  defmacro elixir_to_ast(do: code) do
    quoted_to_ast(code)
  end

  defmacro elixir_to_ast(code) do
    quoted_to_ast(code)
  end

  @doc ~S"""
  Translate the Elixir AST to the Erlang AST.
  """
  @spec quoted_to_ast(elixir_form()) :: erlang_form()
  def quoted_to_ast(qt) do
    env = :elixir_env.new()

    ast =
      :elixir.quoted_to_erl(qt, env)
      |> elem(0)

    Macro.escape(ast)
  end

  @doc ~S"""
  Return the Elixir AST of an Elixir module.
  """
  @spec elixir_ast(module()) :: {:ok, [elixir_form()]}
  def elixir_ast(mod) do
    {:ok, {_, [{:debug_info, {:debug_info_v1, :elixir_erl, abstract_code}}]}} =
      :beam_lib.chunks(get_beam_path_as_charlist(mod), [:debug_info])

    {:ok, _forms} = :elixir_erl.debug_info(:elixir_v1, :module_name, abstract_code, [])
  end

  @doc ~S"""
  Return the Erlang AST of an Erlang or Elixir module.
  """
  @spec erlang_ast(module()) :: {:ok, Gradient.ElixirFileUtils.abstract_forms()}
  def erlang_ast(mod) do
    result =
      mod
      |> get_beam_path_as_charlist()
      |> Gradient.ElixirFileUtils.get_forms_from_beam()

    case result do
      {:ok, _forms} = ok ->
        ok

      error ->
        raise "Could not get erlang forms for module #{inspect(mod)}, error:\n #{inspect(error)}"
    end
  end

  @doc ~S"""
  Print module as Erlang source code.
  """
  @spec print_erlang(module()) :: :ok
  def print_erlang(mod) do
    {:ok, forms} = erlang_ast(mod)
    IO.puts(:erl_prettypr.format(:erl_syntax.form_list(forms)))
  end

  @doc """
  Print module as Elixir source code.

  Based on https://github.com/michalmuskala/decompile by Michał Muskała
  """
  @spec print_elixir(module()) :: :ok
  def print_elixir(mod) do
    {:ok, ast} = elixir_ast(mod)
    {:ok, forms} = erlang_ast(mod)

    format_elixir_code(mod, ast, forms)
  end

  defp format_elixir_code(module, ast, forms) do
    specs =
      forms
      |> Enum.filter(&(match?({:attribute, _line, :spec, _contents}, &1)))
      |> Enum.map(fn {:attribute, _line, :spec, {{_fun, _arity} = fun_arity, types}} ->
        {fun_arity, types}
      end)
      |> Enum.into(%{})

    # Function definitions
    definitions =
      ast.definitions
      |> Enum.reverse()
      |> Enum.map(fn {{name, arity}, kind, _meta, heads} ->
        spec = Map.get(specs, {name, arity})

        %{
          name: name,
          kind: kind,
          heads: heads,
          spec: spec
        }
      end)
      |> Enum.map(&format_definition/1)

    # Types
    types =
      forms
      |> Enum.filter(&(match?({:attribute, _line, :type, _contents}, &1)))
      |> Enum.map(fn {:attribute, _line, :type, {type_name, type, _}} ->
        "@type #{type_name} :: #{Gradient.ElixirType.pretty_print(type)}\n"
      end)

    [
      "defmodule ",
      inspect(module),
      " do\n",
      types,
      definitions,
      "end\n"
    ]
    |> IO.iodata_to_binary()
    |> Code.format_string!()
    |> IO.puts()
  end

  defp format_definition(%{name: name, kind: kind, heads: heads, spec: spec}) do
    # Replace unallowed characters in function names with `_`.
    #
    # This is for cases where the name is like "call (overridable 2)", in which
    # case it'd get converted to "call__overridable_2_".
    name = Regex.replace(~r/[^\w\?\!]/, to_string(name), "_")

    formatted_def =
      Enum.map(heads, fn {_meta, args, _what?, body} ->
        [
          "  #{kind} #{name}(#{Enum.map_join(args, ", ", &Macro.to_string/1)}) do\n    ",
          Macro.to_string(body),
          "\n  end\n\n"
        ]
      end)

    if spec do
      Enum.map(spec, &"@spec #{print_spec(name, &1)}\n") ++ formatted_def
      # ["@spec #{print_spec(name, spec)}\n"] ++ formatted_def
    else
      formatted_def
    end
  end

  # Modified version of Gradient.ElixirType.pretty_print(), for function specs rather than anonymous functions
  defp print_spec(name, {:type, _, :fun, [args, res_type]} = _spec) do
    args = print_spec_args(args)
    res = ElixirType.pretty_print(res_type)
    "#{name}(#{args}) :: #{res}"
  end

  defp print_spec_args({:type, _, :product, arg_types}) do
    arg_types
    |> Enum.map(&ElixirType.pretty_print(&1))
    |> Enum.join(", ")
  end

  defp print_spec_args({:type, _, :any}), do: "..."

  def get_beam_path_as_charlist(mod) when is_list(mod), do: mod
  def get_beam_path_as_charlist(mod) when is_atom(mod), do: :code.which(mod)
end
