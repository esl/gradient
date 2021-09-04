defmodule Proto.Hello do
  @type req :: {:hello, String.t()}
  @type res :: :ok
end
