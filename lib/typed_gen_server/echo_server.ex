defmodule TypedGenServer.EchoServer do
  use GenServer

  @type protocol :: Proto.Echo.req()

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{})
  end

  @impl true
  def init(state) do
    # Schedule work to be performed on start
    {:ok, state}
  end

  @impl true
  def handle_call(m, from, state) do
    handle(m, from, state)
    {:noreply, state}
  end

  @spec handle(protocol()) :: :ok
  defp handle({:echo}) do
    :ok
  end
end
