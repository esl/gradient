defmodule Proto.Echo do
  @type t :: req() | res()
  @type req :: {:echo, pid(), any()}
  @type res :: {:echo, any()}
end
