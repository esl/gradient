defmodule SpecMixed do
  @spec convert(integer()) :: float()
  @spec encode(atom()) :: binary()
  def convert(int) when is_integer(int), do: int / 1
  def convert(atom) when is_atom(atom), do: to_string(atom)

  def encode(atom) when is_atom(atom), do: to_string(atom)
end
