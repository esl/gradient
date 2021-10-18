defmodule Test do
  @type t :: :a | :b

  @spec f(t()) :: :ok | :not_ok
  def f(t) do
    case t do
      :a ->
        :ok
        # :b -> :not_ok
    end
  end

  defmodule R1 do
    require Record
    Record.defrecord(:r1, a: 1)
    @type t :: record(:r1, a: integer())
  end

  defmodule R2 do
    require Record
    Record.defrecord(:r2, b: 1)
    @type t :: record(:r2, b: integer())
  end

  @type record_variants :: R1.t() | R2.t()

  @spec f_records(record_variants()) :: :ok | :not_ok
  def f_records(r) do
    import R1
    import R2

    case r do
      r1(a: _) ->
        :ok
        # r2(b: _) -> :ok
    end
  end

  defmodule S1 do
    defstruct a: 1
    @type t :: %__MODULE__{}
  end

  defmodule S2 do
    defstruct b: 2
    @type t :: %__MODULE__{}
  end

  @type struct_variants :: S1.t() | S2.t()

  @spec f_structs(struct_variants) :: :ok | :not_ok
  def f_structs(s) do
    case s do
      %S1{} ->
        :ok
        # %S2{} -> :not_ok
    end
  end
end
