defmodule TypedGenServer.MultiServer do
  #use GenServer
  use GradualizerEx.TypeAnnotation

  ## recompile(); GradualizerEx.type_check_file(:code.which(TypedGenServer.MultiServer), [:infer])

  #@type message :: Proto.Echo.req() | Proto.Hello.req()
  #@type message :: {:echo_req, String.t()} | {:hello, String.t()}
  #@type state :: map()

  #def start_link(_) do
  #  GenServer.start_link(__MODULE__, %{})
  #end

  ##@spec echo() :: :ok
  #@spec echo() :: Proto.Echo.res()
  #def echo() do
  #  #:ok
  #  #annotate_type( GenServer.call(:pid, :ok), Proto.Echo.res() )
  #  #annotate_type( GenServer.call(:pid, :ok), list() )
  #  #assert_type( GenServer.call(:pid, :ok), :ok)
  #  assert_type( GenServer.call(:pid, :ok), Proto.Echo.res() )
  #end

  #def test() do
  #  [
  #    quote do
  #    "asd"
  #    end,
  #    quote do
  #      'asd'
  #    end,
  #    quote do
  #      :'asd'
  #    end,
  #    quote do
  #      {:string, 0, 'asd'}
  #    end,
  #    unquote({:{}, [], [:string, 0, 'asd']})
  #  ] |> Enum.each(&IO.inspect(&1))
  #end

  @spec echo(pid(), String.t()) :: String.t()
  #@spec echo(pid(), String.t()) :: {:echo_req, String.t()}
  def echo(pid, message) do
    #annotated = assert_type( GenServer.call(pid, {:echo_req, message}), Proto.Echo.res() )
    #annotated = 
    case annotate_type( GenServer.call(pid, {:echo_req, message}), Proto.Echo.res() ) do
      {:echo_res, response} -> response
    end
  end

  #@spec hello(pid, String.t()) :: Proto.Hello.res()
  #def hello(pid, name) do
  #  GenServer.call(pid, {:hello, name})
  #end

  #@impl true
  #def init(state) do
  #  {:ok, state}
  #end

  #@impl true
  #def handle_call(m, from, state) do
  #  {:noreply, handle(m, from, state)}
  #end

  #@spec handle(message(), any, any) :: state()
  #def handle({:echo_req, payload}, from, state) do
  #  GenServer.reply(from, {:echo_res, payload})
  #  state
  #end

  #def handle({:hello, name}, from, state) do
  #  IO.puts("Hello, #{name}!")
  #  GenServer.reply(from, :ok)
  #  state
  #end
end
