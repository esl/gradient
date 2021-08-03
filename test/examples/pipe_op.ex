defmodule Pipe do

  def pipe do
    [1,2,3]
    |> Enum.filter(fn x -> x < 3 end)
    |> length()
  end
end
