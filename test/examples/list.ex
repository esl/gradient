defmodule ListEx do
  @spec wrap(any) :: list()
  def wrap(x), do: [x]

  def list do
    ['11', "12", 1, 2, 3, wrap(4)]
  end

  def ht([a | _]) do
    [a | [1, 2, 3]]
  end

  def ht2([a | _]) do
    [a | wrap(1)]
  end
end
