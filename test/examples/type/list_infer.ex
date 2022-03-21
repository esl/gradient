defmodule ListInfer do
  def f() do
    v = [1, 2]
    g(v)
  end

  @spec g(integer()) :: any()
  def g(val), do: val + 1
end
