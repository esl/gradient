defmodule GradualizerEx.TypeAnnotation do

  defmacro annotate_type(expr, type),
    do: cast(:'::', expr, type)

  defmacro assert_type(expr, type),
    do: cast(:':::', expr, type)

  defp cast(type_op, expr, type) do
    erlang_type = elixir_type_to_erlang(type)
    #IO.inspect(erlang_type, label: "erlang type")
    {type_op, [], [expr, Macro.to_string(erlang_type)]}
    #|> IO.inspect(label: "translate type")
  end

  defp elixir_type_to_erlang(type) do
    case type do
      {{:., _, [{:__aliases__, _, path}, name]}, _, [] = _args} ->
        #unquote({:{}, [], [:string, 0, '\'Elixir.Fake\':t()']})
        #{:string, 0, Macro.escape("'Elixir.#{Enum.join(path, ".")}':#{name}()" |> to_charlist())}
        "'Elixir.#{Enum.join(path, ".")}':#{name}()"
      _ when is_atom(type) ->
        Atom.to_string(type)
      other ->
        #unquote({:{}, [], [:string, 0, '\'Elixir.Fake\':t()']})
        other
    end
  end
  
  defmacro __using__(_) do
    quote [] do
      import GradualizerEx.TypeAnnotation 
      require GradualizerEx.TypeAnnotation

      @compile {:inline, '::': 2, ':::': 2}
      def unquote(:'::')(expr, _type), do: expr
      def unquote(:':::')(expr, _type), do: expr

    end
  end
end
