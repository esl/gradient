defmodule Typespec do
  @type mylist(t) :: [t]

  defstruct name: "", age: 1

  @spec spec_remote_type() :: Unknown.atom()
  def spec_remote_type, do: :ok

  @spec spec_user_type() :: mylist(:ok | atom())
  def spec_user_type, do: [:ok]

  @spec spec_map_and_named_type(type :: Unknown.atom()) :: %{
          optional(:value) => integer(),
          required(:type) => Unknown.atom()
        }
  def spec_map_and_named_type(type), do: %{type: type}

  @spec spec_atom(:ok | nil | true | false) :: Unknown.atom(:ok | nil | true | false)
  def spec_atom(name), do: name

  @spec spec_function() :: (atom(), %{name: String.t()} -> map())
  def spec_function(), do: fn id, %{name: name} -> %{id: id, name: name} end

  @spec spec_struct(%Typespec{}) :: %Typespec{}
  def spec_struct(struct), do: struct

  @spec spec_list([integer(), ...]) :: [...]
  def spec_list(list), do: list

  @spec spec_range(1..10) :: [1..10]
  def spec_range(i), do: [i]

  @spec spec_keyword(a: integer(), b: integer()) :: integer()
  def spec_keyword(a: a, b: b), do: a + b

  @spec spec_tuple({:ok, integer()}) :: tuple()
  def spec_tuple({:ok, a}), do: {:ok, a + 1}

  @spec spec_bitstring(<<_::48, _::_*8>>) :: <<>>
  def spec_bitstring(_), do: <<>>
end
