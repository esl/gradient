defmodule Gradient.AstData do
  @moduledoc """
  Stores the test cases data for expressions line specifying. To increase the flexibility
  the data need normalization before equality assertion. Thus we check only the line change,
  not the exact value and there is no need to update expected values when the file content
  changes.

  This way of testing is useful only for more complex expressions in which we can observe
  some line change. For example, look at the pipe operator cases.
  """

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

  defp pipe_with_fun_converted_to_erl_equivalent do
    {__ENV__.function,
     {__ENV__.line,
      elixir_to_ast do
        :ok
        |> elem(0)
      end, __ENV__.line},
     {:call, 56, {:remote, 56, {:atom, 56, :erlang}, {:atom, 56, :element}},
      [{:integer, 56, 1}, {:atom, 55, :ok}]}}
  end

  @spec ast_data() :: [
          {atom(), {Types.abstract_expr(), Types.tokens(), Types.options()}, tuple()}
        ]
  def ast_data do
    [pipe(), pipe_with_fun_converted_to_erl_equivalent()]
    |> Enum.map(fn {{name, _}, {start_line, ast, end_line}, expected} ->
      tokens = Gradient.Tokens.drop_tokens_to_line(@tokens, start_line)
      {name, {ast, tokens, [line: start_line, end_line: end_line]}, expected}
    end)
  end

  def normalize_expression(expression) do
    {expression, _} =
      :erl_parse.mapfold_anno(
        fn anno, acc ->
          {{:erl_anno.line(anno) - acc, :erl_anno.column(anno)}, acc}
        end,
        :erl_anno.line(elem(expression, 1)),
        expression
      )

    expression
  end
end
