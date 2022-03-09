defmodule TypedGenServer.Stage1.Server do
  # use GenServer
  use Gradient.TypeAnnotation

  ## Start IEx with:
  ##   iex -S mix run --no-start
  ##
  ## Start Gradient:
  ##   Application.ensure_all_started(:gradient)
  ##
  ## Then use the following to recheck the file on any change:
  ##   recompile(); Gradient.type_check_file(:code.which( TypedGenServer.Stage1.Server ), [:infer])

  ## Try switching between the definitions and see what happens
  @type message :: Contract.Echo.req() | Contract.Hello.req()
  # @type message :: Contract.Echo.req()
  # @type message :: {:echo_req, String.t()} | {:hello, String.t()}

  @type state :: map()

  def start_link() do
    GenServer.start_link(__MODULE__, %{})
  end

  @spec echo(pid(), String.t()) :: String.t()
  # @spec echo(pid(), String.t()) :: {:echo_req, String.t()}
  def echo(pid, message) do
    case annotate_type(GenServer.call(pid, {:echo_req, message}), Contract.Echo.res()) do
      # case call_echo(pid, message) do
      ## Try changing the pattern or the returned response
      {:echo_res, response} -> response
    end
  end

  # @spec call_echo(pid(), String.t()) :: Contract.Echo.res()
  # defp call_echo(pid, message) do
  #  GenServer.call(pid, {:echo_req, message})
  # end

  @spec hello(pid(), String.t()) :: :ok
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
  @spec handle_call(message(), GenServer.from(), state())
          :: called(Contract.Echo.res() | Contract.Hello.res())
  ## Try breaking the pattern match, e.g. by changing 'echo_req'
  def handle_call({:echo_req, payload}, _from, state) do
    {:reply, {:echo_res, payload}, state}
  end

  ## Try commenting out the following clause
  def handle_call({:hello, name}, _from, state) do
    IO.puts("Hello, #{name}!")
    {:reply, :ok, state}
  end
end
