defmodule StringExample do
  def string, do: "100"

  def charlist, do: '100'

  def list_of_chars, do: [49, 48, 48]

  def list, do: [1, 2, 3]

  def mixed_list() do
    a = {1, '13'}
    [a, "12", 3, {1, 2}, string()]
  end

  @spec iff() :: integer()
  def iff do
    cond do
      true -> '1'
      true -> 2
    end
  end
end
