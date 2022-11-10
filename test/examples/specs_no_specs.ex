defmodule SpecsNoSpecs do
  @spec f() :: :f1_result
  def f() do
    f1()
  end

  def g() do
    g1()
  end

  @spec f1() :: :f1_result
  defp f1() do
    :f1_result
  end

  defp g1() do
    :g1_result
  end
end
