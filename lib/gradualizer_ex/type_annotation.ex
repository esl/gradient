defmodule GradualizerEx.TypeAnnotation do
  defmacro annotate_type(expr, type) do
    {:"::", [], [expr, Macro.to_string(type)]}
  end

  defmacro assert_type(expr, type) do
    {:":::", [], [expr, Macro.to_string(type)]}
  end

  defmacro __using__(_) do
    quote [] do
      import GradualizerEx.TypeAnnotation
      require GradualizerEx.TypeAnnotation

      @compile {:inline, "::": 2, ":::": 2}
      def unquote(:"::")(expr, _type), do: expr
      def unquote(:":::")(expr, _type), do: expr
    end
  end
end
