defmodule NewMod do
  defmacro __using__(_) do
    quote do
      @spec new(attrs :: map()) :: atom()
      def new(_attrs), do: :ok

      @spec a(attrs :: map()) :: atom()
      def a(_attrs), do: :ok

      @spec b(attrs :: map()) :: atom()
      def b(_attrs), do: :ok
    end
  end
end

defmodule SpecInMacro do
  use NewMod

  @spec c(attrs :: map()) :: atom()
  def c(_attrs), do: :ok
end
