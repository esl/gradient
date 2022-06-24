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
     {:block, 22,
      [
        {:call, 24, {:remote, 24, {:atom, 24, :erlang}, {:atom, 24, :is_atom}},
         [{:integer, 23, 1}]},
        {:call, 27, {:remote, 27, {:atom, 27, :erlang}, {:atom, 27, :is_atom}},
         [{:cons, 26, {:integer, 26, 49}, {nil, 26}}]},
        {:call, 30, {:remote, 30, {:atom, 30, :erlang}, {:atom, 30, :is_atom}},
         [{:atom, 29, :ok}]},
        {:call, 33, {:remote, 33, {:atom, 33, :erlang}, {:atom, 33, :is_atom}},
         [
           {:cons, 32, {:integer, 32, 1},
            {:cons, 32, {:integer, 32, 2}, {:cons, 32, {:integer, 32, 3}, {nil, 32}}}}
         ]},
        {:call, 36, {:remote, 36, {:atom, 36, :erlang}, {:atom, 36, :is_atom}},
         [{:tuple, 35, [{:integer, 35, 1}, {:integer, 35, 2}, {:integer, 35, 3}]}]},
        {:call, 39, {:remote, 39, {:atom, 39, :erlang}, {:atom, 39, :is_atom}},
         [{:bin, 38, [{:bin_element, 38, {:string, 38, 'a'}, :default, :default}]}]}
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

  defp complex_list_pipe do
    {__ENV__.function,
     {__ENV__.line,
      elixir_to_ast do
        [
          {1, %{a: 1}},
          {2, %{a: 2}}
        ]
        |> Enum.map(&elem(&1, 0))
      end, __ENV__.line},
     {:call, 80, {:remote, 80, {:atom, 80, Enum}, {:atom, 80, :map}},
      [
        {:cons, 76,
         {:tuple, 77,
          [
            {:integer, 77, 1},
            {:map, 77, [{:map_field_assoc, 77, {:atom, 77, :a}, {:integer, 77, 1}}]}
          ]},
         {:cons, 77,
          {:tuple, 78,
           [
             {:integer, 78, 2},
             {:map, 78, [{:map_field_assoc, 78, {:atom, 78, :a}, {:integer, 78, 2}}]}
           ]}, {nil, 77}}},
        {:fun, 80,
         {:clauses,
          [
            {:clause, 80, [{:var, 0, :_@1}], [],
             [
               {:call, 80, {:remote, 80, {:atom, 80, :erlang}, {:atom, 80, :element}},
                [{:integer, 80, 1}, {:var, 0, :_@1}]}
             ]}
          ]}}
      ]}}
  end

  defp complex_tuple_pipe do
    {__ENV__.function,
     {__ENV__.line,
      elixir_to_ast do
        {
          {1, %{a: 1}},
          {2, %{a: 2}}
        }
        |> Tuple.to_list()
      end, __ENV__.line},
     {:call, 119, {:remote, 119, {:atom, 119, :erlang}, {:atom, 119, :tuple_to_list}},
      [
        {:tuple, 115,
         [
           {:tuple, 116,
            [
              {:integer, 116, 1},
              {:map, 116, [{:map_field_assoc, 116, {:atom, 116, :a}, {:integer, 116, 1}}]}
            ]},
           {:tuple, 117,
            [
              {:integer, 117, 2},
              {:map, 117, [{:map_field_assoc, 117, {:atom, 117, :a}, {:integer, 117, 2}}]}
            ]}
         ]}
      ]}}
  end

  @spec ast_data() :: [
          {atom(), {Types.abstract_expr(), Types.tokens(), Types.options()},
           Types.abstract_expr()}
        ]
  def ast_data do
    [
      pipe(),
      pipe_with_fun_converted_to_erl_equivalent(),
      complex_list_pipe(),
      complex_tuple_pipe()
    ]
    |> Enum.map(fn {{name, _}, {start_line, ast, end_line}, expected} ->
      tokens = Gradient.Tokens.drop_tokens_to_line(@tokens, start_line + 1)
      {name, {ast, tokens, [line: start_line + 1, end_line: end_line]}, expected}
    end)
  end

  def normalize_expression(expression) do
    {expression, _} =
      :erl_parse.mapfold_anno(
        fn anno, acc ->
          line =
            case :erl_anno.line(anno) - acc do
              line when is_integer(line) and line >= 0 ->
                line
            end

          column =
            case :erl_anno.column(anno) do
              column when is_integer(column) and column > 0 ->
                column
            end

          location = {line, column}
          {location, acc}
        end,
        :erl_anno.line(elem(expression, 1)),
        expression
      )

    expression
  end
end
