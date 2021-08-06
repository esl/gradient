defmodule RecordEx do
  require Record

  @type t :: record(:record_ex, x: integer(), y: integer())
  Record.defrecord(:record_ex, x: 0, y: 0)

  def empty do
    record_ex()
  end

  def init() do
    record_ex(x: 1)
  end

  @spec update(t()) :: t()
  def update(record) do
    record_ex(record, x: 2, y: 3)
  end
end
