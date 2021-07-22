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

  @spec error(integer()) :: map()
  def error(x) do
    %{x: x}
  end
end
