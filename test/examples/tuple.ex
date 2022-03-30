defmodule TupleEx do
  def tuple do
    {:ok, 12}
  end

  def list_in_tuple do
    {:ok, [1, 2, 3]}
  end

  def tuple_in_list do
    [{:a, 12}, {:b, :ok}]
  end

  def tuple_in_str do
    <<"abc #{inspect(:abc, limit: :infinity, label: "abc #{13}")}", 12>>
  end

  def tuple_in_str2 do
    msg =
      "\nElixir formatter not exist for #{inspect({}, pretty: true, limit: :infinity)} using default \n"

    String.to_charlist(IO.ANSI.light_yellow() <> msg <> IO.ANSI.reset())
  end
end
