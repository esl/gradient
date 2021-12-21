defmodule WrongRet do
  @spec ret_wrong_atom() :: atom()
  def ret_wrong_atom, do: 1

  @spec ret_wrong_atom2() :: atom()
  def ret_wrong_atom2, do: {:ok, []}

  @spec ret_wrong_atom3() :: atom()
  def ret_wrong_atom3, do: %{a: 1}

  # @spec ret_wrong_atom4() :: atom()
  # def ret_wrong_atom4, do: false

  @spec ret_wrong_integer() :: integer()
  def ret_wrong_integer, do: 1.0

  @spec ret_wrong_integer2() :: integer()
  def ret_wrong_integer2, do: :ok

  @spec ret_wrong_integer3() :: integer()
  def ret_wrong_integer3, do: true

  @spec ret_wrong_integer4() :: integer()
  def ret_wrong_integer4, do: [1, 2, 3]

  @spec ret_out_of_range_int() :: 1..10
  def ret_out_of_range_int, do: 12

  @spec ret_wrong_float() :: float()
  def ret_wrong_float() do
    1
  end

  @spec ret_wrong_float2() :: float()
  def ret_wrong_float2() do
    nil
  end

  @spec ret_wrong_char() :: char()
  def ret_wrong_char() do
    'Ala ma kota'
  end

  @spec ret_wrong_char2() :: ?o
  def ret_wrong_char2() do
    nil
  end

  @spec ret_wrong_boolean() :: boolean()
  def ret_wrong_boolean, do: :ok

  @spec ret_wrong_boolean2() :: boolean()
  def ret_wrong_boolean2, do: "1234"

  @spec ret_wrong_boolean3() :: boolean()
  def ret_wrong_boolean3, do: 1

  @spec ret_wrong_boolean4() :: boolean()
  def ret_wrong_boolean4, do: [a: 1, b: 2]

  @spec ret_wrong_keyword() :: keyword()
  def ret_wrong_keyword, do: [1, 2, 3]

  @spec ret_wrong_list() :: list()
  def ret_wrong_list, do: ?c

  @spec ret_wrong_tuple() :: tuple()
  def ret_wrong_tuple, do: %{a: 1, b: 2}

  @spec ret_wrong_map() :: map()
  def ret_wrong_map, do: {:a, 1, 2}

  @spec ret_wrong_fun() :: (... -> atom())
  def ret_wrong_fun, do: fn -> 12 end
end
