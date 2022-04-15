defmodule Gradient.Tokens do
  @moduledoc """
  Functions useful for token management.
  """
  alias Gradient.Types, as: T

  @typedoc "Type of conditional with following tokens"
  @type conditional_t() ::
          {:case, T.tokens()}
          | {:cond, T.tokens()}
          | {:unless, T.tokens()}
          | {:if, T.tokens()}
          | {:with, T.tokens()}
          | :undefined

  @doc """
  Drop tokens to the first conditional occurrence. Returns type of the encountered
  conditional and the following tokens.
  """
  @spec get_conditional(T.tokens(), integer(), T.options()) :: conditional_t()
  def get_conditional(tokens, line, opts) do
    conditionals = [:if, :unless, :cond, :case, :with]
    {:ok, limit_line} = Keyword.fetch(opts, :end_line)

    drop_tokens_while(tokens, limit_line, fn
      {:do_identifier, _, c} -> c not in conditionals
      {:paren_identifier, _, c} -> c not in conditionals
      {:identifier, _, c} -> c not in conditionals
      _ -> true
    end)
    |> case do
      [token | _] = tokens when elem(elem(token, 1), 0) == line -> {elem(token, 2), tokens}
      _ -> :undefined
    end
  end

  @doc """
  Drop tokens to the first list occurrence. Returns type of the encountered
  list and the following tokens.
  """
  @spec get_list(T.tokens(), T.options()) ::
          {:list, T.tokens()} | {:keyword, T.tokens()} | {:charlist, T.tokens()} | :undefined
  def get_list(tokens, opts) do
    tokens = flatten_tokens(tokens)
    {:ok, limit_line} = Keyword.fetch(opts, :end_line)

    res =
      drop_tokens_while(tokens, limit_line, fn
        {:"[", _} -> false
        {:list_string, _, _} -> false
        {:kw_identifier, _, id} when id not in [:do] -> false
        _ -> true
      end)

    case res do
      [{:"[", _} | _] = list -> {:list, list}
      [{:list_string, _, _} | _] = list -> {:charlist, list}
      [{:kw_identifier, _, _} | _] = list -> {:keyword, list}
      _ -> :undefined
    end
  end

  @doc """
  Drop tokens to the first tuple occurrence. Returns type of the encountered 
  list and the following tokens.
  """
  @spec get_tuple(T.tokens(), T.options()) ::
          {:tuple, T.tokens()} | :undefined
  def get_tuple(tokens, opts) do
    {:ok, limit_line} = Keyword.fetch(opts, :end_line)

    res =
      drop_tokens_while(tokens, limit_line, fn
        {:"{", _} -> false
        {:kw_identifier, _, _} -> false
        _ -> true
      end)

    case res do
      [{:"{", _} | _] = tuple -> {:tuple, tuple}
      [{:kw_identifier, _, _} | _] = tuple -> {:tuple, tuple}
      _ -> :undefined
    end
  end

  @doc """
  Drop tokens till the matcher returns false or the token's line exceeds the limit.
  """
  @spec drop_tokens_while(T.tokens(), integer(), (T.token() -> boolean())) :: T.tokens()
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

  @doc """
  Drop tokens while the token's line is lower than the given location.
  """
  @spec drop_tokens_to_line(T.tokens(), integer()) :: T.tokens()
  def drop_tokens_to_line(tokens, line) do
    Enum.drop_while(tokens, fn t ->
      elem(elem(t, 1), 0) < line
    end)
  end

  @doc """
  Get location from token.
  """
  @spec get_loc_from_token(T.token()) :: {integer(), integer()}
  def get_loc_from_token(token), do: {elem(elem(token, 1), 0), elem(elem(token, 1), 1)}

  @doc """
  Get line from token.
  """
  @spec get_line_from_token(T.token()) :: integer()
  def get_line_from_token(token), do: elem(elem(token, 1), 0)

  def get_line_from_form(form) do
    form
    |> elem(1)
    |> :erl_anno.line()
  end

  @doc """
  Drop the tokens to binary occurrence and then collect all belonging tokens. 
  Return tuple where the first element is a list of tokens making up the binary, and the second 
  element is a list of tokens after the binary.
  """
  @spec cut_tokens_to_bin(T.tokens(), integer()) :: {T.tokens(), T.tokens()}
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

  @doc """
  Flatten the tokens, mostly binaries or string interpolation.
  """
  @spec flatten_tokens(T.tokens()) :: T.tokens()
  def flatten_tokens(tokens) do
    Enum.map(tokens, &flatten_token/1)
    |> Enum.concat()
  end

  @spec select_tokens_in_paren(T.tokens(), T.line()) :: T.tokens()
  def select_tokens_in_paren(tokens, line) do
    tokens
    |> drop_tokens_to_line(line)
    |> find_opening_paren()
    |> find_closing_paren()
  end

  def get_closing_paren_loc(tokens, line \\ 0) do
    case select_tokens_in_paren(tokens, line) do
      [] ->
        :undefined

      list ->
        {line, col, _} = elem(List.last(list), 1)
        {line, col}
    end
  end

  # Private

  defp find_opening_paren(tokens) do
    drop_tokens_while(tokens, fn
      {:"(", _} -> false
      _ -> true
    end)
  end

  defp find_closing_paren(tokens, init \\ 0)
  defp find_closing_paren([], _), do: []

  defp find_closing_paren(tokens, init) do
    Enum.reduce_while(tokens, {[], init}, fn
      {:")", _} = t, {ts, 1} -> {:halt, [t | ts]}
      {:")", _} = t, {ts, open} when open > 1 -> {:cont, {[t | ts], open - 1}}
      {:"(", _} = t, {ts, open} -> {:cont, {[t | ts], open + 1}}
      t, {ts, open} -> {:cont, {[t | ts], open}}
    end)
    |> case do
      {_, _open} ->
        raise "Cannot find closing paren in given tokens"

      list ->
        list
    end
  end

  defp flatten_token(token) do
    case token do
      {:bin_string, _, [s]} = t when is_binary(s) ->
        [t]

      {:bin_string, _, ts} ->
        flatten_tokens(ts)

      {{_, _, nil}, {_, _, nil}, ts} ->
        flatten_tokens(ts)

      str when is_binary(str) ->
        [{:str, {0, 0, nil}, str}]

      _otherwise ->
        [token]
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
end
