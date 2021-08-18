defmodule AnnotationTest do
  @moduledoc """
  Documentation for `AnnotationTest`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> AnnotationTest.hello()
      :world

  """

  use GradualizerEx.TypeAnnotation

  @spec hello() :: boolean()
  def hello do
    a = 12
    annotate_type(a, integer())
  end
end
