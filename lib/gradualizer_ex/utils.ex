defmodule GradualizerEx.Utils do
  def drop_tokens_to_line(tokens, line) do
    Enum.drop_while(tokens, fn t ->
      elem(elem(t, 1), 0) < line
    end)
  end

  def get_line_from_token(token), do: elem(elem(token, 1), 0)

  def get_line_from_form(form) do
    form
    |> elem(1)
    |> get_line_from_loc()
  end

  def get_line_from_loc(loc) when is_integer(loc), do: loc

  def get_line_from_loc(loc) do
    {:ok, line} = Keyword.fetch(loc, :location)
    line
  end

  def was_generate?(meta) when is_integer(meta), do: false
  def was_generate?(meta), do: Keyword.get(meta, :generated, false)

  def sort_forms(forms) do
    forms
    |> Enum.sort_by(&get_line_from_form/1)
  end

  def cut_tokens_to_bin(tokens, line) do
    tokens = drop_tokens_to_line(tokens, line)

    Enum.drop_while(tokens, fn
      {:"<<", _} -> false
      {:bin_string, _, _} -> false
      _ -> true
    end)
    |> case do
      [{:"<<", _} | _] = ts -> cut_bottom(ts, 0)
      [{:bin_string, _, _} = t | _] -> [t]
      otherwise -> otherwise
    end
  end

  defp cut_bottom([{:"<<", _} = t | ts], deep) do
    [t | cut_bottom(ts, deep + 1)]
  end

  defp cut_bottom([{:">>", _} = t | ts], deep) do
    if deep - 1 > 0 do
      [t | cut_bottom(ts, deep - 1)]
    else
      [t]
    end
  end

  defp cut_bottom([t | ts], deep), do: [t | cut_bottom(ts, deep)]

  def flat_tokens(tokens) do
    Enum.map(tokens, &flat_token/1)
    |> Enum.concat()
  end

  def flat_token(token) do
    case token do
      {:bin_string, _, [s]} = t when is_binary(s) ->
        [t]

      {:bin_string, _, ts} ->
        flat_tokens(ts)

      {{_, _, nil}, {_, _, nil}, ts} ->
        flat_tokens(ts)

      str when is_binary(str) ->
        [{:str, {0, 0, nil}, str}]

      _otherwise ->
        [token]
    end
  end

  # def concat_bit_string(tokens) do
  # tokens
  # |> Enum.map(fn {:bin_string loc, s} -> )
  # end
end
