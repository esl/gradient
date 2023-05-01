# gradient:disable-file
defmodule ConfigComments.WholeFile do
  @spec ret_wrong_atom() :: atom()
  def ret_wrong_atom, do: 1
end
