defmodule Stage3.TypedServer do

  ## This doesn't play well with:
  ##   {:ok, srv} = MultiServer.start_link()
  ## Due to:
  ##   The pattern {ok, _srv@1} on line 90 doesn't have the type 'Elixir.TypedServer':on_start(t())
  ## A bug/limitation in Gradualizer pattern match typing?
  @type on_start(t) :: {:ok, t} | :ignore | {:error, {:already_started, t} | any()}

  def wrap(on_start, module) do
    case on_start do
      {:ok, pid} -> {:ok, {module, pid}}
      {:error, {:already_started, pid}} -> {:error, {:already_started, {module, pid}}}
      other -> other
    end
  end
end

defmodule TypedGenServer.Stage3.Server do
  use GenServer
  use Gradient.TypeAnnotation
  alias Stage3.TypedServer

  ## Start IEx with:
  ##   iex -S mix run --no-start
  ##
  ## Then use the following to recheck the file on any change:
  ##   recompile(); Gradient.type_check_file(:code.which( TypedGenServer.Stage3.Server ), [:infer])

  @opaque t :: {__MODULE__, pid()}

  ## Try switching between the definitions and see what happens
  @type message :: Contract.Echo.req() | Contract.Hello.req()
  #@type message :: Contract.Echo.req()
  #@type message :: {:echo_req, String.t()} | {:hello, String.t()}

  @type state :: map()

  @spec start_link() :: TypedServer.on_start(t())
  def start_link() do
    GenServer.start_link(__MODULE__, %{}) |> TypedServer.wrap(__MODULE__)
  end

  @spec echo(t(), String.t()) :: String.t()
  # @spec echo(t(), String.t()) :: {:echo_req, String.t()}
  def echo(_server = {__MODULE__, _pid}, message) do
    case annotate_type( GenServer.call(_pid, {:echo_req, message}), Contract.Echo.res() ) do
    #case call_echo(_server, message) do
      ## Try changing the pattern or the returned response
      {:echo_res, response} -> response
    end
  end

  #@spec call_echo(t(), String.t()) :: Contract.Echo.res()
  #defp call_echo({__MODULE__, pid}, message) do
  #  GenServer.call(pid, {:echo_req, message})
  #end

  @spec hello(t(), String.t()) :: :ok
  def hello({__MODULE__, pid}, name) do
    case GenServer.call(pid, {:hello, name}) |> annotate_type(Contract.Hello.res()) do
      :ok -> :ok
    end
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
  ## Try breaking the pattern match, e.g. by changing 'echo_req'
  def handle({:echo_req, payload}, from, state) do
    GenServer.reply(from, {:echo_res, payload})
    state
  end

  ## Try commenting out the following clause
  def handle({:hello, name}, from, state) do
    IO.puts("Hello, #{name}!")
    GenServer.reply(from, :ok)
    state
  end
end

defmodule Test.TypedGenServer.Stage3.Server do
  alias TypedGenServer.Stage3.Server

  ## Typecheck with:
  ##   recompile(); Gradient.type_check_file(:code.which( Test.TypedGenServer.Stage3.Server ), [:infer])

  @spec test :: any()
  def test do
    {:ok, srv} = Server.start_link()
    pid = self()
    "payload" = Server.echo(srv, "payload")
    ## This won't typecheck, since Server.echo only accepts Server.t(), that is Server pids
    #"payload" = Server.echo(pid, "payload")
  end
end
