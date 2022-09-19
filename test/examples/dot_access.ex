defmodule DotAccess do
  defmodule Waiter do
    defstruct attempt_num: 0
  end

  @spec delay_default(%Waiter{}) :: timeout()
  def delay_default(%Waiter{} = waiter) do
    waiter.attempt_num * 10
  end
end
