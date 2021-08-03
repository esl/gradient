defmodule Conditional.Guard do
  @spec guarded_fun(integer()) :: :ok
  def guarded_fun(x) when x > 3 and x < 6 when is_integer(x), do: :ok

  @spec guarded_case(integer()) :: {:ok, integer()} | :error
  def guarded_case(x) do
    case x do
      0 -> {:ok, 1}
      i when i > 0 -> {:ok, i + 1}
      _otherwise -> :error
    end
  end
end
