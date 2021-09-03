defmodule TypedGenServer.MultiServer do
  use GenServer

  @type protocol :: Proto.Echo.req() | Proto.Hello.req()
  #@type protocol :: {:echo_req, any()} | {:hello, list()}

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{})
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call(m, from, state) do
    handle(m, from, state)
    {:noreply, state}
  end

  @spec handle(protocol(), any, any) :: :ok
  defp handle({:echo_req, payload}, from, _state) do
    GenServer.reply(from, {:echo_res, payload})
    :ok
  end
end
