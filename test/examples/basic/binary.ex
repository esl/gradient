defmodule Basic.Binary do
  def bin, do: <<49, 48, 48>>

  def bin_block do
    <<49, 48, 48>>
  end

  def complex do
    x = fn x -> x + 1 end
    <<49, 48, x.(50)>>
  end

  def complex2 do
    "abc #{inspect(12)} cba"
  end
end
