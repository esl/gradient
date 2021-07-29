defmodule GradualizerEx.Fmt do
  @callback format_type_error(error :: any(), opts :: any()) :: :io_lib.chars()
end
