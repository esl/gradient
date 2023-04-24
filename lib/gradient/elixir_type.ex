defmodule Gradient.ElixirType do
  @moduledoc """
  Convert the Erlang abstract types to the Elixir code.
  """

  alias Gradient.ElixirFmt

  @type abstract_type() :: Gradient.Types.abstract_type()

  @doc """
  Convert abstract type to Elixir code and format output with formatter.
  """
  @spec pp_type_format(abstract_type(), keyword()) :: iodata()
  def pp_type_format(type, fmt_opts \\ []) do
    type
    |> pretty_print()
    |> Code.format_string!(fmt_opts)
  end

  @doc """
  Take type and prepare a pretty string representation.
  """
  @spec pretty_print(abstract_type()) :: String.t()
  def pretty_print({:remote_type, _, [{:atom, _, mod}, {:atom, _, name}, args]}) do
    args_str = Enum.map(args, &pretty_print(&1)) |> Enum.join(", ")
    name_str = Atom.to_string(name)
    mod_str = ElixirFmt.parse_module(mod)
    mod_str <> name_str <> "(#{args_str})"
  end

  def pretty_print({:user_type, _, type, args}) do
    args_str = Enum.map(args, &pretty_print(&1)) |> Enum.join(", ")
    type_str = Atom.to_string(type)
    "#{type_str}(#{args_str})"
  end

  def pretty_print({:ann_type, _, [var_name, var_type]}) do
    # gradient:disable-for-next-line
    pretty_print(var_name) <> " :: " <> pretty_print(var_type)
  end

  def pretty_print({:type, _, :map, :any}) do
    "map()"
  end

  def pretty_print({:type, _, :map, assocs}) do
    assocs_str = Enum.map(assocs, &association_type(&1)) |> Enum.join(", ")
    "%{" <> assocs_str <> "}"
  end

  def pretty_print({:op, _, op, type}) do
    Atom.to_string(op) <> " " <> pretty_print(type)
  end

  def pretty_print({:op, _, op, left_type, right_type}) do
    operator = " " <> Atom.to_string(op) <> " "
    pretty_print(left_type) <> operator <> pretty_print(right_type)
  end

  def pretty_print({:type, _, :fun, []}) do
    "fun()"
  end

  def pretty_print({:type, _, :fun, [{:type, _, :product, arg_types}, res_type]}) do
    args = Enum.map(arg_types, &pretty_print(&1)) |> Enum.join(", ")
    res = pretty_print(res_type)
    "(" <> args <> " -> " <> res <> ")"
  end

  def pretty_print({:type, _, :fun, [{:type, _, :any}, res_type]}) do
    res = pretty_print(res_type)
    "(... -> " <> res <> ")"
  end

  def pretty_print({:type, _, :range, [low, high]}) do
    pretty_print(low) <> ".." <> pretty_print(high)
  end

  def pretty_print({:type, _, :tuple, :any}) do
    "tuple()"
  end

  def pretty_print({:type, _, :tuple, elements}) do
    elements_str = Enum.map(elements, &pretty_print(&1)) |> Enum.join(", ")
    "{" <> elements_str <> "}"
  end

  def pretty_print({:atom, _, val}) when val in [nil, true, false] do
    Atom.to_string(val)
  end

  def pretty_print({:atom, _, val}) do
    case Atom.to_string(val) do
      "Elixir." <> mod -> mod
      str -> ":\"" <> str <> "\""
    end
  end

  def pretty_print({:integer, _, val}) do
    Integer.to_string(val)
  end

  def pretty_print({:type, _, :binary, _}) do
    "binary()"
  end

  def pretty_print({:type, _, nil, []}) do
    # The empty list type [] cannot be distinguished from the predefined type nil()
    "[]"
  end

  def pretty_print({:type, _, :union, [{:atom, _, true}, {:atom, _, false}]}) do
    "boolean()"
  end

  def pretty_print({:type, _, :union, args}) do
    args |> Enum.map(&pretty_print/1) |> Enum.join(" | ")
  end

  def pretty_print({:type, _, type, args}) do
    args_str = Enum.map(args, &pretty_print(&1)) |> Enum.join(", ")
    Atom.to_string(type) <> "(#{args_str})"
  end

  def pretty_print({:var, _, t}) when is_atom(t) do
    Atom.to_string(t)
  end

  def pretty_print(type) do
    "#{inspect(type)}"
  end

  ######
  ### Private
  ######

  @spec association_type(tuple()) :: String.t()
  defp association_type({:type, _, :map_field_assoc, [key, value]}) do
    key_str = pretty_print(key)
    value_str = pretty_print(value)
    "optional(#{key_str}) => #{value_str}"
  end

  defp association_type({:type, _, :map_field_exact, [key, value]}) do
    key_str = pretty_print(key)
    value_str = pretty_print(value)
    "required(#{key_str}) => #{value_str}"
  end
end
