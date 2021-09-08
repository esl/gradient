defmodule Stage4.TypedServer.CompileTime do
  @moduledoc false

  def __before_compile__(env) do
    #IO.inspect(env, limit: :infinity)
    IO.inspect(Module.get_attribute(env.module, :call_types), label: "call types")
  end

  #defmacro __before_compile__(env) do
  #  #IO.inspect(env, limit: :infinity)
  #  quote do
  #    @spec call_example(pid(), any()) :: any()
  #    def call_example(pid, req) do
  #      GenServer.call(pid, req)
  #    end
  #  end
  #end

  def __on_definition__(env, kind, name, args, guards, body) do
    request_handler = Module.get_attribute(env.module, :request_handler)
    case request_handler do
      ^name ->
        response_type = find_response_type(env, body)
        #Module.put_attribute(env.module, :call_types, {Enum.at(args, 0), response_type})
        #IO.inspect(env, label: "env")
        Module.put_attribute(env.module, :call_types, {Enum.at(args, 0), body})
      _ ->
        :ok
    end
    #IO.puts("Defining #{kind} named #{name} with args:")
    #IO.inspect(args |> Enum.map(&Macro.to_string/1))
    #IO.puts("and guards")
    #IO.inspect(guards)
    #IO.puts("and body")
    #IO.puts(Macro.to_string(body))
    #IO.puts("")
  end

  defp find_response_type(env, do: block) do
    try do
      find_response_type(env, block)
      :not_found
    catch
      {:response_type, response_type} -> response_type
    end
  end

  defp find_response_type(env, {:., _, args}) do
    case args do
      {:__aliases__, _, [alias_ | _]} ->
        IO.inspect({alias_, alias_.__info__(:module)}, label: "alias info")
    end
    find_response_type(env, args)
  end
  defp find_response_type(_, _) do
    :ok
  end
end

defmodule Stage4.TypedServer do
  defmacro __using__(_) do
    quote do
      Module.register_attribute(__MODULE__, :call_types, accumulate: true)
      @before_compile Stage4.TypedServer.CompileTime
      @on_definition Stage4.TypedServer.CompileTime
    end
  end

  def wrap(on_start, module) do
    case on_start do
      {:ok, pid} -> {:ok, {module, pid}}
      {:error, {:already_started, pid}} -> {:error, {:already_started, {module, pid}}}
      other -> other
    end
  end

  #defmacro reply(client, reply, type) do
  #  #IO.inspect(__ENV__, label: "__ENV__", limit: :infinity)
  #  IO.inspect(__CALLER__, label: "__CALLER__", limit: :infinity)
  #  quote bind_quoted: [client: client, reply: reply] do
  #    GenServer.reply(client, reply)
  #  end
  #end
end

defmodule TypedGenServer.Stage4.Server do
  use GenServer
  use GradualizerEx.TypeAnnotation
  use Stage4.TypedServer
  alias Stage4.TypedServer

  ## Start IEx with:
  ##   iex -S mix run --no-start
  ##
  ## Then use the following to recheck the file on any change:
  ##   recompile(); GradualizerEx.type_check_file(:code.which( TypedGenServer.Stage4.Server ), [:infer])

  @opaque t :: {__MODULE__, pid()}

  ## Try switching between the definitions and see what happens
  @type message :: Contract.Echo.req() | Contract.Hello.req()
  # @type message :: Contract.Echo.req()
  # @type message :: {:echo_req, String.t()} | {:hello, String.t()}

  @type state :: map()

  @spec start_link() :: {:ok, t()} | :ignore | {:error, {:already_started, t()} | any()}
  def start_link() do
    GenServer.start_link(__MODULE__, %{}) |> TypedServer.wrap(__MODULE__)
  end

  @spec echo(t(), String.t()) :: String.t()
  # @spec echo(t(), String.t()) :: {:echo_req, String.t()}
  def echo(_server = {__MODULE__, _pid}, message) do
    #case annotate_type(GenServer.call(_pid, {:echo_req, message}), Contract.Echo.res()) do
    case call_echo(_server, message) do
      ## Try changing the pattern or the returned response
      {:echo_res, response} -> response
    end
  end

  ## This could be generated based on present handle clauses - thanks, Robert!
  @spec call_echo(t(), String.t()) :: Contract.Echo.res()
  defp call_echo({__MODULE__, pid}, message) do
    GenServer.call(pid, {:echo_req, message})
  end

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

  @request_handler :handle

  @spec handle(message(), any, any) :: state()
  ## Try breaking the pattern match, e.g. by changing 'echo_req'
  def handle({:echo_req, payload}, from, state) do
    ## This could register {:echo_req, payload} <-> {:echo_res, payload} mapping
    ## and response type at compile time to generate call_echo() automatically.
    ## Thanks Robert!
    TypedServer.reply( from, {:echo_res, payload}, Contract.Echo.res() )
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
  ##   recompile(); GradualizerEx.type_check_file(:code.which( Test.TypedGenServer.Stage4.Server ), [:infer])

  @spec test :: any()
  def test do
    {:ok, srv} = Server.start_link()
    pid = self()
    "payload" = Server.echo(srv, "payload")
    ## This won't typecheck, since Server.echo only accepts Server.t(), that is our Server pids
    # "payload" = Server.echo(pid, "payload")
  end
end
