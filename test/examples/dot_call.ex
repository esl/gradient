defmodule DotCall do
  @spec call_module(module()) :: integer()
  def call_module(mod) do
    mod.some_function()
  end
end
