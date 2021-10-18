defmodule Call do
  def get_x(_a, _b, _c), do: 10

  @spec call() :: integer()
  def call do
    get_x(
      "ala",
      'ala',
      12
    )
  end
end
