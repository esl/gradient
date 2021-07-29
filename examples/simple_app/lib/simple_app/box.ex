defmodule SimpleApp.Box do
  def x, do: 10
  def y, do: true

  @spec to_int(String.t()) :: charlist()
  def to_int(_square), do: "100"

  @spec to_int2(String.t()) :: String.t()
  def to_int2(_square) do
    :ok
    #a = {1,2}
    #[a,"12", 3, {1,2},  x()]
  end
end
