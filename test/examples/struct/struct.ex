defmodule StructEx do
  defstruct x: 0, y: 0

  def empty do
    %StructEx{}
  end

  def update do
    %{empty() | x: 13}
  end

  def get do
    %StructEx{x: _x} = update()
  end

  def get2 do
    _x = update().x
  end
end
