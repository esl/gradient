defmodule Annotations.ShouldPass do
  use Gradient.TypeAnnotation

  @spec f(list(integer())) :: integer()
  def f(l) do
    l |> assert_type(nonempty_list()) |> hd()
  end
end

defmodule Annotations.ShouldFail.NoAnno do
  @spec f(list(integer())) :: integer()
  def f(l) do
    l |> hd()
  end
end

defmodule Annotations.ShouldFail.BadAnno do
  use Gradient.TypeAnnotation

  @spec f(list(integer())) :: integer()
  def f(l) do
    l |> assert_type(float()) |> hd()
  end
end
