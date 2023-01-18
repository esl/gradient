defmodule CorrectSpec do
  @spec convert(integer()) :: float()
  def convert(int) when is_integer(int), do: int / 1
  @spec convert(atom()) :: binary()
  def convert(atom) when is_atom(atom), do: to_string(atom)

  @spec encode(atom() | integer()) :: binary() | float()
  def encode(val) do
    case val do
      _ when is_integer(val) -> val / 1
      _ when is_atom(val) -> to_string(val)
    end
  end
end
