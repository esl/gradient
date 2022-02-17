defmodule TypespecBeh do
  @callback vital_fun() :: %{atom() => any()}
  @callback non_vital_fun() :: a when a: {integer(), atom()}
  @macrocallback non_vital_macro(arg :: any) :: Macro.t()
  @optional_callbacks non_vital_fun: 0, non_vital_macro: 1
end
