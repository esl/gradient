defmodule Doublespec do
  @spec convert(integer()) :: float()
  @spec convert(atom()) :: binary()
  def convert(int) when is_integer(int), do: int / 1
  def convert(atom) when is_atom(atom), do: to_string(atom)

  @spec convert(atom()) :: binary()
  def last_two(list) do
    [last, penultimate | _tail] = Enum.reverse(list)
    [penultimate, last]
  end

  @spec last_two(atom()) :: atom()
  def last_three(:ok) do
    :ok
  end
end
