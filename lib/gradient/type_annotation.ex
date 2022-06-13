defmodule Gradient.TypeAnnotation do
  defmodule Type do
    def to_erlang(type) do
      type
      |> to_erlang_ast()
      |> :erl_pp.expr()
      # See Gradient.AstSpecifier.mapper(:'::'()) for the reason why to_string() is sufficient.
      |> to_string()
    end

    defp to_erlang_ast(type) do
      case type do
        {{:., _, [{:__aliases__, _, path}, name]}, _, args} ->
          ## TODO: this is unsafe, but OTOH there's no guarantee that a remote/invalid module
          ## will be available to load locally or its name already loaded at check time...
          erlang_mod = Module.concat([Elixir | path])
          erlang_args = for a <- args, do: to_erlang_ast(a)
          {:call, 0, {:remote, 0, {:atom, 0, erlang_mod}, {:atom, 0, name}}, erlang_args}

        {name, _, args} ->
          erlang_args = for a <- args, do: to_erlang_ast(a)
          {:call, 0, {:atom, 0, name}, erlang_args}

        a when is_atom(a) ->
          {:atom, 0, a}
      end
    end
  end

  defmacro annotate_type(expr, type) do
    erlang_type = Type.to_erlang(type)

    quote do
      unquote(:"::")(unquote(expr), unquote(erlang_type))
    end
  end

  defmacro assert_type(expr, type) do
    erlang_type = Type.to_erlang(type)

    quote do
      unquote(:":::")(unquote(expr), unquote(erlang_type))
    end
  end

  defmacro __using__(_) do
    quote [] do
      import Gradient.TypeAnnotation
      require Gradient.TypeAnnotation

      @compile {:inline, "::": 2, ":::": 2}
      def unquote(:"::")(expr, _type), do: expr
      def unquote(:":::")(expr, _type), do: expr
    end
  end
end
