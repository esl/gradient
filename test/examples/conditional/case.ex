defmodule Conditional.Case do
  def case_,
    do:
      (case 5 do
         5 -> :ok
         _ -> :error
       end)

  def case_block do
    case 5 do
      5 -> :ok
      _ -> :error
    end
  end
end
