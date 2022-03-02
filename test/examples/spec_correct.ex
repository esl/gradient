defmodule CorrectSpec do
  @spec convert(integer()) :: float()
  def convert(int) when is_integer(int), do: int / 1
  @spec convert(atom()) :: binary()
  def convert(atom) when is_atom(atom), do: to_string(atom)
end
