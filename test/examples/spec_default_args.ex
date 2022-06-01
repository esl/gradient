defmodule SpecDefaultArgs do
  @spec foo(integer, integer, integer) :: integer
  def foo(arg1, arg2 \\ 1, arg3 \\ 2)

  def foo(arg1, arg2, arg3) do
    arg1 + arg2 - arg3
  end
end
