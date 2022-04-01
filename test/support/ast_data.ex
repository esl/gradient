defmodule Gradient.AstData do
  require Gradient.Debug
  import Gradient.Debug, only: [elixir_to_ast: 1]
  import Gradient.TestHelpers
  alias Gradient.Types

  @tokens __ENV__.file |> load_tokens()

  defp pipe do
    {__ENV__.function,
     {__ENV__.line,
      elixir_to_ast do
        1
        |> is_atom()

        '1'
        |> is_atom()

        :ok
        |> is_atom()

        [1, 2, 3]
        |> is_atom()

        {1, 2, 3}
        |> is_atom()

        "a"
        |> is_atom()
      end, __ENV__.line},
     {:block, 11,
      [
        {:call, 14, {:remote, 14, {:atom, 14, :erlang}, {:atom, 14, :is_atom}},
         [{:integer, 13, 1}]},
        {:call, 17, {:remote, 17, {:atom, 17, :erlang}, {:atom, 17, :is_atom}},
         [{:cons, 16, {:integer, 16, 49}, {nil, 16}}]},
        {:call, 20, {:remote, 20, {:atom, 20, :erlang}, {:atom, 20, :is_atom}},
         [{:atom, 19, :ok}]},
        {:call, 23, {:remote, 23, {:atom, 23, :erlang}, {:atom, 23, :is_atom}},
         [
           {:cons, 22, {:integer, 22, 1},
            {:cons, 22, {:integer, 22, 2}, {:cons, 22, {:integer, 22, 3}, {nil, 22}}}}
         ]},
        {:call, 26, {:remote, 26, {:atom, 26, :erlang}, {:atom, 26, :is_atom}},
         [{:tuple, 25, [{:integer, 25, 1}, {:integer, 25, 2}, {:integer, 25, 3}]}]},
        {:call, 29, {:remote, 29, {:atom, 29, :erlang}, {:atom, 29, :is_atom}},
         [{:bin, 28, [{:bin_element, 28, {:string, 28, 'a'}, :default, :default}]}]}
      ]}}
  end

  @spec ast_data() :: [{Types.abstract_expr(), Types.tokens(), Types.options()}]
  def ast_data do
    [pipe()]
    |> Enum.map(fn {{name, _}, {start_line, ast, end_line}, expected} ->
      tokens = Gradient.Tokens.drop_tokens_to_line(@tokens, start_line)
      {name, {ast, tokens, [line: start_line, end_line: end_line]}, expected}
    end)
  end
end
