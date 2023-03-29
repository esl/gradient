defmodule SimpleApp.Exhaustiveness do
  @type t ::
          {:int, integer()}
          | {:not_int, boolean()}

  @spec should_raise_nonexhaustive_error(t) :: :ok
  def should_raise_nonexhaustive_error(t) do
    case t do
      {:int, _} -> :ok
    end
  end
end
