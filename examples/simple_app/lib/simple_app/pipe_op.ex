defmodule SimpleApp.PipeOp do

  use Gradient.TypeAnnotation

  @spec int_inc(integer()) :: integer()
  def int_inc(int) do
    int + 1
  end

  def easy_pipe do
    '1'
    |> int_inc()
    '1'
    |> int_inc()
    '1'
    |> int_inc()
    '1'
    |> int_inc()
  end

  def easy_pipe2 do
    int_inc(
      {%{a: 1, b: 2, c: 3},
      %{a: 1, b: 2, c: 3},
      %{a: 1, b: 2, c: 3}})

  end

end
