defmodule TypedGenServer.MultiServer do
  use GenServer

  @type protocol :: Proto.Echo.req() | Proto.Hello.req()
  # @type protocol :: {:echo_req, String.t()} | {:hello, String.t()}
  @type state :: map()

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{})
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call(m, from, state) do
    {:noreply, handle(m, from, state)}
  end

  @spec handle(protocol(), any, any) :: state()
  def handle({:echo_reqz, payload}, from, state) do
    GenServer.reply(from, {:echo_res, payload})
    state
  end

  # def handle({:hello, name}, from, state) do
  #  IO.puts("Hello, #{name}!")
  #  GenServer.reply(from, :ok)
  #  state
  # end
end
