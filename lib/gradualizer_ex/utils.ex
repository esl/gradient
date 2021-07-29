defmodule GradualizerEx.Utils do
  def drop_tokens_to_line(tokens, line) do
    Enum.drop_while(tokens, fn t ->
      elem(elem(t, 1), 0) < line
    end)
  end

  def get_line_from_token(token), do: elem(elem(token, 1), 0)

  def get_line_from_loc(loc) when is_integer(loc), do: loc

  def get_line_from_loc(loc) do
    {:ok, line} = Keyword.fetch(loc, :location)
    line
  end
end
