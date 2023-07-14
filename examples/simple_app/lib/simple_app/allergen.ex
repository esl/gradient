defmodule Allergen do

  @type t() :: :eggs
             | :chocolate
             | :pollen
             | :cats

  @spec score(t()) :: integer()
  def score(allergen) do
    case allergen do
      :eggs -> 1
      :chocolate -> 32
      :pollen -> 64
    end
  end

end
