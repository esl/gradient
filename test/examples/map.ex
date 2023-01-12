defmodule MapEx do
  def empty_map do
    %{}
  end

  def test_map do
    %{a: 12, b: empty_map()}
  end

  def test_map_str do
    %{"a" => 12, "b" => 0}
  end

  def pattern_matching do
    %{a: a} = test_map()
    %{b: ^a} = test_map()
  end

  def pattern_matching_str do
    %{"a" => _a} = test_map()
  end
end
