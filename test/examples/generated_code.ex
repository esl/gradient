defmodule GeneratedCode do
  @moduledoc """
  Module that `use`s another module, and as a result of that, gets generated
  code that contains a warning.

  Since the warning is in code from another module, the warning should not be
  emitted from this one.
  """

  use GeneratingCode

  # What does it look like when we define the function here?
  # @doc """
  # Function with incorrect return value.
  # """
  # @spec wrong_ret2() :: atom()
  # def wrong_ret2() do
  #   1234
  # end

  # Example of a function with some code marked as `generated: true` in the AST
  # def tuple_in_str do
  #   <<"abc #{inspect(:abc, limit: :infinity, label: "abc #{13}")}", 12>>
  # end
end
