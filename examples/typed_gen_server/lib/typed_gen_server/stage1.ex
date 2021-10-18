defmodule TypedGenServer.Stage1.Server do
  use GenServer
  use GradualizerEx.TypeAnnotation

  ## Start IEx with:
  ##   iex -S mix run --no-start
  ##
  ## Then use the following to recheck the file on any change:
  ##   recompile(); GradualizerEx.type_check_file(:code.which( TypedGenServer.Stage1.Server ), [:infer])

  ## Try switching between the definitions and see what happens
  @type message :: Contract.Echo.req() | Contract.Hello.req()
  #@type message :: Contract.Echo.req()
  #@type message :: {:echo_req, String.t()} | {:hello, String.t()}

  @type state :: map()

  def start_link() do
    GenServer.start_link(__MODULE__, %{})
  end

  @spec echo(pid(), String.t()) :: String.t()
  # @spec echo(pid(), String.t()) :: {:echo_req, String.t()}
  def echo(pid, message) do
    case annotate_type( GenServer.call(pid, {:echo_req, message}), Contract.Echo.res() ) do
    #case call_echo(pid, message) do
      ## Try changing the pattern or the returned response
      {:echo_res, response} -> response
    end
  end

  #@spec call_echo(pid(), String.t()) :: Contract.Echo.res()
  #defp call_echo(pid, message) do
  #  GenServer.call(pid, {:echo_req, message})
  #end

  @spec hello(pid(), String.t()) :: :ok
  def hello(pid, name) do
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
