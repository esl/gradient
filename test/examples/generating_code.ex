defmodule GeneratingCode do
  @moduledoc """
  Module that generates code containing a warning.
  """

  defmacro __using__(_) do
    quote do
      @doc """
      Function with incorrect return value.
      """
      @spec wrong_ret() :: atom()
      def wrong_ret() do
        1234
      end
    end
  end
end
