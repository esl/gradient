defmodule SpecWrongName do
  @spec convert(integer()) :: float()
  def convert(int) when is_integer(int), do: int / 1

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
