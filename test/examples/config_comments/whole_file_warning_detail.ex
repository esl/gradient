# gradient:disable-for-file spec_error no_spec
defmodule ConfigComments.WholeFileWarningDetail do
  @spec ret_wrong_atom() :: atom()
  def ret_wrong_atom, do: 1
end
