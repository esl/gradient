defmodule Annotations.ShouldPass do
  use Gradient.TypeAnnotation

  @spec f(list(integer())) :: integer()
  def f(l) do
    l |> assert_type(nonempty_list()) |> hd()
  end

  @spec remote_type_anno(String.t() | atom()) :: [String.t()]
  def remote_type_anno(s) do
    case s do
      a when is_atom(a) -> to_string(a)
      s -> s
    end |> assert_type(String.t()) |> String.split(" ")
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
