defmodule TypeDef do
  @type t() :: integer()
end

defmodule FunDef do
  @spec f() :: TypeDef.t()
  def f(), do: 1
end
