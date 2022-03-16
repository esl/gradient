defmodule SWrongRet do
  @spec ret_wrong_atom() :: atom()
  def ret_wrong_atom, do: 1

  @spec ret_wrong_atom2() :: atom()
  def ret_wrong_atom2, do: {:ok, []}
end
