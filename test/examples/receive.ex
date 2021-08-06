defmodule Receive do
  def recv2 do
    send(self(), {:hello, "All"})

    receive do
      {:hello, to} ->
        IO.puts("Hello, " <> to)

      :skip ->
        :ok
    after
      1_000 ->
        IO.puts("Timeout")
    end
  end

  def recv do
    receive do
      :ok -> :ok
    end
  end
end
