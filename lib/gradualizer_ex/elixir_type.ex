defmodule GradualizerEx.ElixirType do
  @moduledoc """
  Module to format types.

  TODO records
  FIXME add tests
  """

  @doc """
  Take type and prepare pretty string represntation.
  """
  @spec pretty_print(tuple()) :: String.t()
  def pretty_print({:remote_type, _, [{:atom, _, mod}, {:atom, _, type}, args]}) do
    args_str = Enum.map(args, &pretty_print(&1)) |> Enum.join(", ")
    type_str = Atom.to_string(type)
    mod_str = parse_module(mod)
    mod_str <> type_str <> "(#{args_str})"
  end

  def pretty_print({:user_type, _, type, args}) do
    args_str = Enum.map(args, &pretty_print(&1)) |> Enum.join(", ")
    type_str = Atom.to_string(type)
    "#{type_str}(#{args_str})"
  end

  def pretty_print({:ann_type, _, [var_name, var_type]}) do
    pretty_print(var_name) <> pretty_print(var_type)
  end

  def pretty_print({:type, _, :map, :any}) do
    "map()"
  end

  def pretty_print({:type, _, :map, assocs}) do
    assocs_str = Enum.map(assocs, &association_type(&1)) |> Enum.join(", ")
    "%{" <> assocs_str <> "}"
  end

  def pretty_print({:op, _, op, type}) do
    Atom.to_string(op) <> pretty_print(type)
  end

  def pretty_print({:op, _, op, left_type, right_type}) do
    operator = " " <> Atom.to_string(op) <> " "
    pretty_print(left_type) <> operator <> pretty_print(right_type)
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

  def pretty_print({:type, _, :tuple, :any}) do
    "tuple()"
  end

  def pretty_print({:type, _, :tuple, elements}) do
    elements_str = Enum.map(elements, &pretty_print(&1)) |> Enum.join(", ")
    "{" <> elements_str <> "}"
  end

  def pretty_print({:atom, _, nil}) do
    "nil"
  end

  def pretty_print({:atom, _, val}) when val in [true, false] do
    Atom.to_string(val)
  end

  def pretty_print({:atom, _, val}) do
    ":" <> Atom.to_string(val)
  end

  def pretty_print({:integer, _, val}) do
    Integer.to_string(val)
  end

  def pretty_print({:type, _, :binary, _}) do
    "binary()"
  end

  def pretty_print({:type, _, nil, []}) do
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

  def pretty_print(type) do
    "#{inspect(type)}"
  end

  ######
  ### Private
  ######

  @spec parse_module(atom()) :: String.t()
  defp parse_module(:elixir), do: ""

  defp parse_module(mod) do
    case Atom.to_string(mod) do
      "Elixir." <> mod_str -> mod_str <> "."
      mod -> mod <> "."
    end
  end

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
