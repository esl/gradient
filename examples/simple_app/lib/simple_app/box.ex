defmodule SimpleApp.Box do
  @spec get_l() :: {:ok, integer()} | :error
  def get_l, do: {:ok, 5}

  @spec get_w() :: {:ok, integer()} | :error
  def get_w, do: {:ok, 4}

  @spec get_h() :: {:ok, integer()} | :error
  def get_h, do: {:ok, 10}

  @spec volume() :: integer()
  def volume do
    with {:ok, l} <- get_l(),
         {:ok, w} <- get_w(),
         {:ok, h} <- get_h() do
      l * w * h
    else
      _ ->
        "wrong parameter"
    end
  end
end
