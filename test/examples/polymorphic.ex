defmodule Polymorphic do
  @spec k([String.t() | integer() | charlist()]) :: list()
  def k(l), do: :lists.map(&takes_an_intersection/1, l)

  @spec takes_an_intersection(String.t()) :: String.t()
  def takes_an_intersection(b) when is_binary(b), do: b

  @spec takes_an_intersection(integer()) :: integer()
  def takes_an_intersection(i) when is_integer(i), do: i
end
