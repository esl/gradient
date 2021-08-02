defmodule SimpleApp.Box do
  # def x, do: 10
  # def y, do: true

  # @spec to_int(String.t()) :: charlist()
  # def to_int(_square), do: "100"

  # @spec to_int2(String.t()) :: String.t()
  # def to_int2(square) do
  # if String.length(square) > 10 do
  # "ok"
  # else
  # if square == "abcd" do
  # "ok"
  # else
  # "error"
  # end
  # end
  # end

  @spec ok_res() :: {:ok, list(integer)} | {:error, term()}
  def ok_res, do: {:ok, [1, 2, 3]}

  @spec test_with() :: integer()
  def test_with do
    with {:ok, _a} <- ok_res(),
         {:ok, _b} <- ok_res() do
      1
    else
      _ ->
        '12'
    end
  end
end
