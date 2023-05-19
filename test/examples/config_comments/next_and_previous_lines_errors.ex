defmodule ConfigComments.NextAndPreviousLinesErrors do
  @spec ret_wrong_atom() :: atom()
  # gradient:disable-next-line
  def ret_wrong_atom, do: 1

  @spec ret_wrong_atom3() :: atom()
  # gradient:disable-next-line type_error mismatch
  def ret_wrong_atom3, do: 1

  @spec ret_wrong_atom4() :: atom()
  def ret_wrong_atom4, do: 1
  # gradient:disable-previous-line

  @spec ret_wrong_atom5() :: atom()
  def ret_wrong_atom5, do: 1
  # gradient:disable-previous-line type_error mismatch

  # This one isn't suppressed and will result in an error
  @spec ret_wrong_atom6() :: atom()
  def ret_wrong_atom6, do: 1
end
