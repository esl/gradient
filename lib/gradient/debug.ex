defmodule Gradient.Debug do
  @moduledoc false

  def elixir_ast(mod) do
    {:ok, {_, [{:debug_info, {:debug_info_v1, :elixir_erl, abstract_code}}]}} = 
      :beam_lib.chunks(get_beam_path_as_charlist(mod), [:debug_info])
    {:ok, _forms} = :elixir_erl.debug_info(:elixir_v1, :module_name, abstract_code, [])
  end

  def erlang_ast(mod) do
    {:ok, _forms} = get_beam_path_as_charlist(mod) |> Gradient.ElixirFileUtils.get_forms_from_beam()
  end

  def print_erlang(mod) do
    {:ok, forms} = erlang_ast(mod)
    IO.puts(:erl_prettypr.format(:erl_syntax.form_list(forms)))
  end

  def get_beam_path_as_charlist(mod) when is_list(mod), do: mod
  def get_beam_path_as_charlist(mod) when is_atom(mod), do: :code.which(mod)
end
