defmodule Conditional.Unless do
  def unless_block do
    unless false do
      :ok
    else
      :error
    end
  end
end
