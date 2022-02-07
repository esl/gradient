defmodule Gradient.Debug do
  @moduledoc ~S"""
  Helpers for convenient debugging Erlang and Elixir ASTs.
  """

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
  @spec erlang_ast(module()) :: {:ok, [erlang_form()]}
  def erlang_ast(mod) do
    {:ok, _forms} =
      get_beam_path_as_charlist(mod) |> Gradient.ElixirFileUtils.get_forms_from_beam()
  end

  @doc ~S"""
  Print module as Erlang source code.
  """
  @spec print_erlang(module()) :: :ok
  def print_erlang(mod) do
    {:ok, forms} = erlang_ast(mod)
    IO.puts(:erl_prettypr.format(:erl_syntax.form_list(forms)))
  end

  def get_beam_path_as_charlist(mod) when is_list(mod), do: mod
  def get_beam_path_as_charlist(mod) when is_atom(mod), do: :code.which(mod)
end
