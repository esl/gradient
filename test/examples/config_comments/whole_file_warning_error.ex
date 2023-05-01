# gradient:disable-file type_error mismatch
defmodule ConfigComments.WholeFileWarningError do
  @spec ret_wrong_atom() :: atom()
  def ret_wrong_atom, do: 1

  @spec nonexistent_remote_spec() :: SomeRemoteModule.type()
  def nonexistent_remote_spec, do: 5
end
