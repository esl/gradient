defmodule Shared.Utils.Structs do
  @moduledoc """
  Set of functions used across the app, for utility purposes, like dealing with
  tuples, maps and other data structures.
  """

  alias Morphix

  @spec string_map_to_struct(
          data :: map,
          target_struct :: module | struct
        ) ::
          target_struct :: struct
  def string_map_to_struct(data, target_struct) do
    data
    # string maps to atom maps
    |> Morphix.atomorphiform!()
    |> data_to_struct(target_struct)
  end

  @spec data_to_struct(data :: Enumerable.t(), target_struct :: module | struct) ::
          target_struct :: struct
  def data_to_struct(data, target_struct), do: struct(target_struct, data)
end
