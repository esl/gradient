defmodule SpecWrongArgsArity do
  @spec foo(integer, integer, integer) :: integer
  def foo(arg1, arg2 \\ 1)

  def foo(arg1, arg2) do
    arg1 + arg2
  end

  def foo(arg1, arg2, args3) do
    arg1 + arg2 - args3
  end
end
