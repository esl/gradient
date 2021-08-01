defmodule Conditional.If do
  def if_,
    do:
      (if 1 < 5 do
         :ok
       else
         :error
       end)

  def if_inline, do: if(1 < 5, do: :ok, else: :error)

  def if_block do
    if 1 < 5 do
      :ok
    else
      :error
    end
  end
end
