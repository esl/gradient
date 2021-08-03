defmodule ListComprehension do
  def lc do
    for n <- 0..5, rem(n, 3) == 0, do: n * n
  end
end
