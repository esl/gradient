defmodule Typespec do
  @type mylist(t) :: [t]

  @spec missing_type() :: Unknown.atom()
  def missing_type, do: :ok

  @spec missing_type_arg() :: mylist(Unknown.atom())
  def missing_type_arg, do: [:ok]

  @spec named_type(name :: Unknown.atom()) :: atom()
  def named_type(name), do: name

  @spec atoms_type(:ok | :error) :: :ok | :error
  def atoms_type(name), do: name

  @spec atoms_type2(:ok | :error) :: Unknown.atom(:ok | :error)
  def atoms_type2(name), do: name
end
