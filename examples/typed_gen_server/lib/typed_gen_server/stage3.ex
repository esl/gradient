defmodule Stage3.TypedServer do
  ## This doesn't play well with:
  ##   {:ok, srv} = MultiServer.start_link()
  ## Due to:
  ##   The pattern {ok, _srv@1} on line 90 doesn't have the type 'Elixir.TypedServer':on_start(t())
  ## A bug/limitation in Gradualizer pattern match typing?
  @type on_start(t) :: {:ok, t} | :ignore | {:error, {:already_started, t} | any()}
end

defmodule TypedGenServer.Stage3.Server do
  use GenServer
  use Gradient.TypeAnnotation
  alias Stage3.TypedServer

  ## Start IEx with:
  ##   iex -S mix run --no-start
  ##
  ## Start Gradient:
  ##   Application.ensure_all_started(:gradient)
  ##
  ## Then use the following to recheck the file on any change:
  ##   recompile(); Gradient.type_check_file(:code.which( TypedGenServer.Stage3.Server ), [:infer])

  @opaque t :: pid()

  ## Try switching between the definitions and see what happens
  @type message :: Contract.Echo.req() | Contract.Hello.req()
  # @type message :: Contract.Echo.req()
  # @type message :: {:echo_req, String.t()} | {:hello, String.t()}

  @type state :: %{}

  @spec start_link() :: TypedServer.on_start(t())
  def start_link() do
    GenServer.start_link(__MODULE__, %{})
  end

  @spec echo(t(), String.t()) :: String.t()
  # @spec echo(t(), String.t()) :: {:echo_req, String.t()}
  def echo(pid, message) do
    case annotate_type(GenServer.call(pid, {:echo_req, message}), Contract.Echo.res()) do
      # case call_echo(_server, message) do
      ## Try changing the pattern or the returned response
      {:echo_res, response} -> response
    end
  end

  # @spec call_echo(t(), String.t()) :: Contract.Echo.res()
  # defp call_echo({__MODULE__, pid}, message) do
  #  GenServer.call(pid, {:echo_req, message})
  # end

  @spec hello(t(), String.t()) :: :ok
  def hello(pid, name) do
    case GenServer.call(pid, {:hello, name}) |> annotate_type(Contract.Hello.res()) do
      :ok -> :ok
    end
  end

  # @impl true
  def init(state) do
    {:ok, state}
  end

  @type called(a) :: {:noreply, state()}
                   | {:reply, a, state()}

  # @impl true
  @spec handle_call(message(), GenServer.from(), state()) ::
          called(Contract.Echo.res() | Contract.Hello.res())
  def handle_call(message, _from, state) do
    handle(message, state)
  end

  @spec handle(message(), state()) :: called(Contract.Echo.res() | Contract.Hello.res())
  ## Try breaking the pattern match, e.g. by changing 'echo_req'
  def handle({:echo_req, payload}, state) do
    {:reply, {:echo_res, payload}, state}
  end

  ## Try commenting out the following clause
  def handle({:hello, name}, state) do
    IO.puts("Hello, #{name}!")
    {:reply, :ok, state}
  end
end

defmodule Test.TypedGenServer.Stage3.Server do
  alias TypedGenServer.Stage3.Server

  ## Run with:
  ##   recompile(); Test.TypedGenServer.Stage3.Server.test()
  ##
  ## Typecheck with:
  ##   recompile(); Gradient.type_check_file(:code.which( Test.TypedGenServer.Stage3.Server ), [:infer])
  ##   recompile(); Gradient.type_check_file(:code.which( Test.TypedGenServer.Stage3.Server ), [:infer, ex_check: false])

  @spec test :: any()
  def test do
    {:ok, srv} = Server.start_link()

    pid =
      spawn(fn ->
        receive do
          :unlikely -> :ok
        end
      end)

    "payload" = Server.echo(srv, "payload")
    ## This won't typecheck, since Server.echo only accepts Server.t(), that is our Server pids
    # "payload" = Server.echo(pid, "payload")
  end
end
