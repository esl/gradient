defmodule Gradient.Utils do
  @moduledoc """
  Utility functions that helps obtain info about location from data 
  """

  @doc """
  Drop tokens till the matcher returns false or the token's line exceeds the limit.
  """
  def drop_tokens_while(tokens, limit_line \\ -1, matcher)
  def drop_tokens_while([], _, _), do: []

  def drop_tokens_while([token | tokens] = all, limit_line, matcher) do
    line = get_line_from_token(token)

    limit_passed = limit_line < 0 or line < limit_line

    cond do
      matcher.(token) and limit_passed ->
        drop_tokens_while(tokens, limit_line, matcher)

      not limit_passed ->
        []

      true ->
        all
    end
  end

  def drop_tokens_to_line(tokens, line) do
    Enum.drop_while(tokens, fn t ->
      elem(elem(t, 1), 0) < line
    end)
  end

  def get_line_from_token(token), do: elem(elem(token, 1), 0)

  def get_line_from_form(form) do
    form
    |> elem(1)
    |> :erl_anno.line()
  end

  def cut_tokens_to_bin(tokens, line) do
    tokens = drop_tokens_to_line(tokens, line)

    drop_tokens_while(tokens, fn
      {:"<<", _} -> false
      {:bin_string, _, _} -> false
      _ -> true
    end)
    |> case do
      [{:"<<", _} | _] = ts -> cut_bottom(ts, 0)
      [{:bin_string, _, _} = t | ts] -> {[t], ts}
      [] -> {[], tokens}
    end
  end

  defp cut_bottom([{:"<<", _} = t | ts], deep) do
    {ts, cut_ts} = cut_bottom(ts, deep + 1)
    {[t | ts], cut_ts}
  end

  defp cut_bottom([{:">>", _} = t | ts], deep) do
    if deep - 1 > 0 do
      {ts, cut_ts} = cut_bottom(ts, deep - 1)
      {[t | ts], cut_ts}
    else
      {[t], ts}
    end
  end

  defp cut_bottom([t | ts], deep) do
    {ts, cut_ts} = cut_bottom(ts, deep)
    {[t | ts], cut_ts}
  end

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
end
