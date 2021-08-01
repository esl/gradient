defmodule Conditional.Cond do
  def cond_(a),
    do:
      (cond do
         a == :ok -> :ok
         a > 5 -> :ok
         true -> :error
       end)

  def cond_block do
    a = 5

    cond do
      a == :ok -> :ok
      a > 5 -> :ok
      true -> :error
    end
  end
end
