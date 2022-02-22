defmodule TypespecWhen do
  @spec foo({:a, x}) :: {:a, x} | {:b, x} when x: term()
  def foo({:a, x}) do
    case x do
      :foo ->
        {:a, x}

      _ ->
        {:b, x}
    end
  end
end
