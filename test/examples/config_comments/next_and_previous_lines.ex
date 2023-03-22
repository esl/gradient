defmodule ConfigComments.NextAndPreviousLines do
  @spec ret_wrong_atom() :: atom()
  # gradient:disable-for-next-line
  def ret_wrong_atom, do: 1

  @spec ret_wrong_atom2() :: atom()
  # gradient:disable-for-next-line call_undef
  def ret_wrong_atom2, do: 1

  @spec ret_wrong_atom3() :: atom()
  # gradient:disable-for-next-line spec_error no_spec
  def ret_wrong_atom3, do: 1

  @spec ret_wrong_atom4() :: atom()
  def ret_wrong_atom4, do: 1
  # gradient:disable-for-previous-line

  @spec ret_wrong_atom5() :: atom()
  def ret_wrong_atom5, do: 1
  # gradient:disable-for-previous-line call_undef

  @spec ret_wrong_atom6() :: atom()
  def ret_wrong_atom6, do: 1
  # gradient:disable-for-previous-line spec_error no_spec
end
