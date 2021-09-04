defmodule TypedGenServer.MultiServer do
  use GenServer

  @type message :: Proto.Echo.req() | Proto.Hello.req()
  # @type message :: {:echo_req, String.t()} | {:hello, String.t()}
  @type state :: map()

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{})
  end

  @spec echo(pid(), String.t()) :: Proto.Echo.res()
  def echo(pid, message) do
    case GenServer.call(pid, {:echo_req, message})
  end

  @spec hello(pid, String.t()) :: Proto.Hello.res()
  def hello(pid, name) do
    GenServer.call(pid, {:hello, name})
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call(m, from, state) do
    {:noreply, handle(m, from, state)}
  end

  @spec handle(message(), any, any) :: state()
  def handle({:echo_req, payload}, from, state) do
    GenServer.reply(from, {:echo_res, payload})
    state
  end

  def handle({:hello, name}, from, state) do
    IO.puts("Hello, #{name}!")
    GenServer.reply(from, :ok)
    state
  end
end
