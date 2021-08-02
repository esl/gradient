defmodule Conditional.With do
  @spec ok_res() :: {:ok, list(integer)} | {:error, term()}
  def ok_res, do: {:ok, [1, 2, 3]}

  @spec test_with() :: integer()
  def test_with do
    with {:ok, _a} <- ok_res() do
      12
    else
      _ ->
        '12'
    end
  end
end
