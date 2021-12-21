defmodule ListComprehension do
  def lc do
    for n <- [1, 2, 3], do: n
  end

  def bc do
    for <<(r::8 <- <<1, 2, 3, 4, 5>>)>>, into: <<>>, do: <<r>>
  end

  def lc_complex do
    for n <- 0..5, rem(n, 3) == 0, do: n * n
  end
end
