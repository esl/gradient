defmodule AnnotationTest do
  @moduledoc """
  Documentation for `AnnotationTest`.
  """

  use Gradient.TypeAnnotation

  @doc """
  Hello world.

  ## Examples

      iex> AnnotationTest.hello()
      :world

  """

  @spec hello() :: boolean()
  def hello do
    a = 12
    annotate_type(a, integer())
  end
end

defmodule AnnotationTest.ImportExample do
  import AnnotationTest, except: ["::": 2]
end
