defmodule SpecAfterSpec do
  @spec convert(integer()) :: float()
  @spec convert(atom()) :: binary()
  def convert(int) when is_integer(int), do: int / 1
  def convert(atom) when is_atom(atom), do: to_string(atom)
end
