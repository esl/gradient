defmodule RecordType do
  require Record
  Record.defrecord(:user, name: "john", age: 25)

  @type user :: record(:user, name: String.t(), age: integer)

  @spec ret_wrong_record() :: user()
  def ret_wrong_record(), do: :ok

  @spec ret_wrong_record2() :: user()
  def ret_wrong_record2(), do: user(name: 12)

  @spec ret_wrong_atom() :: atom()
  def ret_wrong_atom(), do: user(name: "Kate")
end
