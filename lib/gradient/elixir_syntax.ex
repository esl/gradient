defmodule Gradient.ElixirSyntax do
  @moduledoc ~S"""
  Support for features present in the Elixir syntax, but not in the Erlang abstract syntax tree.
  """

  @doc ~S"""
  Filter out errors caused by the Elixir dot access operator.

  Consider the following Elixir code:

  ```
  @spec delay_default(%Waiter{}) :: timeout()
  defp delay_default(%Waiter{} = waiter) do
    waiter.attempt_num * 10
  end
  ```

  Although the spec says that `waiter` is a struct, the Elixir `.` operator can also be used
  to call a function. Because of that the Elixir compiler has to generate code that can handle
  both of these situations.
  There's some redundancy in this code which, in the light of the type information available
  to the type checker but not the compiler, leads to reporting some misleading error messages.
  This function filters these errors out.
  """
  ## Apparently, `mix format` can't handle Erlang code in triple backticks in doc strings,
  ## so this example is written as a comment instead.
  ##
  ## The Elixir code above is compiled to the following Erlang (abstract syntax tree):
  ##
  ## ```
  ## -spec delay_default(#{'__struct__' := 'Elixir.ExWaiter.Waiter', ...}) -> timeout().
  ## delay_default(#{'__struct__' := 'Elixir.ExWaiter.Waiter'} = _waiter@1) ->
  ##   case _waiter@1 of
  ##     #{attempt_num := _@1} ->
  ##       _@1;
  ##     _@1 when erlang:is_map(_@1) ->
  ##       erlang:error({badkey, attempt_num, _@1});
  ##     _@1 ->
  ##       _@1:attempt_num()
  ##   end * 10.
  ## ```
  @spec dot_operator_errors(any()) :: boolean()
  def dot_operator_errors({_, {:type_error, :unreachable_clauses, clauses}}) do
    not Enum.all?(clauses, fn {:clause, anno, _vars, _guards, _body} ->
      :erl_anno.generated(anno)
    end)
  end

  def dot_operator_errors(
        {_,
         {:type_error, :pattern, _,
          {:map, _,
           [
             {:map_field_exact, _, {:atom, fun_anno, _function_name},
              {:var, _var_anno, _var_name}}
           ]}, _called_expr_type}}
      ) do
    ## Ideally, we would also check for `generated: true` in `_var_anno`, but Elixir 1.11 doesn't
    ## set it, whereas the error shape is exactly the same so we cannot add another match
    ## in the function head.
    ## TODO: use System.version() to do it
    not :erl_anno.generated(fun_anno)
  end

  def dot_operator_errors(_) do
    true
  end
end
