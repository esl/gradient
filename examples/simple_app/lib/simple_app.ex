defmodule SimpleApp do
  @moduledoc """
  Documentation for `SimpleApp`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> SimpleApp.hello()
      :world

  """
  def hello do
    :world
  end

  @spec wrong_return_a(boolean()) :: integer()
  def wrong_return_a(x) do
    x
  end

  @spec bool_id(boolean()) :: boolean()
  def bool_id(x) do
    y = 13
    x + y + 12
  end

  @spec one_line() :: atom()
  def one_line, do: :ok

  @spec lambda() :: atom()
  def lambda do
    l = fn -> :ok end
    l.()
  end
end
