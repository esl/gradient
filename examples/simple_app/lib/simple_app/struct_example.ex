defmodule SimpleApp.StructExample do
  defmodule SomeStruct do
    defstruct name: "John Smith", age: 25
  end

  @type t :: %SomeStruct{}

  @spec age(t) :: non_neg_integer
  def age(%SomeStruct{age: age}), do: age

  @spec mistake :: :ok
  def mistake do
    age(%{first: "John", last: "Smith", age: 32})
  end
end
