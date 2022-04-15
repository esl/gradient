defmodule Gradient.Anno do
  @type anno :: keyword()
  @type location :: {non_neg_integer(), pos_integer()}
  @type line :: non_neg_integer()

  @max_col 1000

  @spec end_location(anno()) :: location()
  def end_location(anno) when is_list(anno) do
    case Keyword.fetch(anno, :end_location) do
      {:ok, {line, col}} -> {abs_line(line(anno), line), col}
      :error -> line(anno)
    end
  end

  def end_location(anno), do: {line(anno), @max_col}

  def end_line(anno) when is_list(anno) do
    case Keyword.fetch(anno, :end_location) do
      {:ok, {line, _}} -> abs_line(line(anno), line)
      :error -> line(anno)
    end
  end

  def end_line(anno), do: line(anno)

  @spec line(anno()) :: line()
  def line(anno), do: :erl_anno.line(:erl_anno.from_term(anno))

  @spec location(anno()) :: location()
  def location(anno) do
    case :erl_anno.location(:erl_anno.from_term(anno)) do
      {line, col} -> {line, col}
      line -> {line, 1}
    end
  end

  def abs_line(startl, endl) when startl > endl, do: 2 * startl - endl
  def abs_line(_, endl), do: endl
end
