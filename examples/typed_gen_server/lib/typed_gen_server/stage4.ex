defmodule TypedGenServer.Stage4.Server do
  use GenServer
  use Gradient.TypeAnnotation
  use Gradient.TypedServer
  alias Gradient.TypedServer

  ## Start IEx with:
  ##   iex -S mix run --no-start
  ##
  ## Then use the following to recheck the file on any change:
  ##   recompile(); Gradient.type_check_file(:code.which( TypedGenServer.Stage4.Server ), [:infer])

  @opaque t :: pid()

  ## Try switching between the definitions and see what happens
  @type message :: Contract.Echo.req() | Contract.Hello.req()
  # @type message :: Contract.Echo.req()
  # @type message :: {:echo_req, String.t()} | {:hello, String.t()}

  @type state :: map()

  @spec start_link() :: {:ok, t()} | :ignore | {:error, {:already_started, t()} | any()}
  def start_link() do
    GenServer.start_link(__MODULE__, %{})
  end

  @spec echo(t(), String.t()) :: String.t()
  # @spec echo(t(), String.t()) :: {:echo_req, String.t()}
  def echo(pid, message) do
    #case annotate_type(GenServer.call(pid, {:echo_req, message}), Contract.Echo.res()) do
    case call_echo_req(pid, message) do
      ## Try changing the pattern or the returned response
      {:echo_res, response} -> response
    end
  end

  ## This is generated with the correct return type,
  ## thanks to using TypedServer.reply/3 instead of GenServer.reply/2.
  ## We don't have to define it!
  ## TODO: use the correct type instead of any as the second param!
  #@spec call_echo_req(t(), any) :: Contract.Echo.res()
  #defp call_echo_req(pid, message) do
  #  GenServer.call(pid, {:echo_req, message})
  #end

  @spec hello(t(), String.t()) :: :ok
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
  ## Try breaking the pattern match, e.g. by changing 'echo_req'
  def handle({:echo_req, payload}, from, state) do
    ## TypedServer.reply/3 registers a {:echo_req, payload} <-> Contract.Echo.res() mapping
    ## and generates call_echo_req() at compile time.
    ## Thanks for the idea, @rvirding!
    TypedServer.reply( from, {:echo_res, payload}, Contract.Echo.res() )
    ## This will not typecheck - awesome!
    #TypedServer.reply( from, {:invalid_tag, payload}, Contract.Echo.res() )
    ## And this is the well known untyped equivalent.
    #GenServer.reply(from, {:echo_res, payload})
    state
  end

  ## Try commenting out the following clause
  def handle({:hello, name}, from, state) do
    IO.puts("Hello, #{name}!")
    GenServer.reply(from, :ok)
    state
  end
end

defmodule Test.TypedGenServer.Stage4.Server do
  alias TypedGenServer.Stage4.Server

  ## Typecheck with:
  ##   recompile(); Gradient.type_check_file(:code.which( Test.TypedGenServer.Stage4.Server ), [:infer])

  @spec test :: any()
  def test do
    {:ok, srv} = Server.start_link()
    pid = self()
    "payload" = Server.echo(srv, "payload")
    ## This won't typecheck, since Server.echo only accepts Server.t(), that is our Server pids
    #"payload" = Server.echo(pid, "payload")
  end
end
