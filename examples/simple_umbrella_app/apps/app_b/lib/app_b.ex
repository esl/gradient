defmodule AppB do
  @moduledoc """
  Documentation for `AppB`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> AppB.hello()
      :world

  """
  def hello do
    AppA.hello()
  end
end
