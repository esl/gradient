# gradient:disable-for-file call_undef
defmodule ConfigComments.WholeFileWarning do
  @spec ret_wrong_atom() :: atom()
  def ret_wrong_atom, do: 1
end
