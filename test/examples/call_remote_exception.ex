defmodule CallRemoteException do
  def call(_conn, _opts) do
    try do
      :ok
    rescue
      e in Plug.Conn.WrapperError ->
        exception = Exception.normalize(:error, e.reason, e.stack)
        _ = Sentry.capture_exception(exception, stacktrace: e.stack, event_source: :plug)
        Plug.Conn.WrapperError.reraise(e)

      e ->
        _ = Sentry.capture_exception(e, stacktrace: __STACKTRACE__, event_source: :plug)
        :erlang.raise(:error, e, __STACKTRACE__)
    catch
      kind, reason ->
        message = "Uncaught #{kind} - #{inspect(reason)}"
        stack = __STACKTRACE__
        _ = Sentry.capture_message(message, stacktrace: stack, event_source: :plug)
        :erlang.raise(kind, reason, stack)
    end
  end
end
