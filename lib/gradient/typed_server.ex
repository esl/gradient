defmodule Gradient.TypedServer do

  ## TODO: docs, docs, docs!

  defmacro __using__(_) do
    quote do
      Module.register_attribute(__MODULE__, :response_types, accumulate: true)
      @before_compile Gradient.TypedServer.CompileHooks
      @on_definition Gradient.TypedServer.CompileHooks
    end
  end

  defmacro reply(client, reply, type) do
    quote do
      reply = unquote(reply)
      annotate_type(reply, unquote(type))
      GenServer.reply(unquote(client), reply)
    end
  end
end
