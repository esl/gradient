defmodule Stage4.TypedServer.CompileHooks do
  @moduledoc false

  defmacro __before_compile__(env) do
    response_types = Module.get_attribute(env.module, :response_types)
    #IO.inspect(response_types, label: "response types")
    for {request_tag, response_type} <- response_types do
      name = Macro.escape(:'call_#{request_tag}')
      quote do
        @spec unquote(name)(t(), any) :: unquote(response_type)
        defp unquote(name)(pid, arg) do
          GenServer.call(pid, {unquote(request_tag), arg})
        end
      end
    end
  end

  def __on_definition__(env, kind, name, args, guards, body) do
    request_handler = Module.get_attribute(env.module, :request_handler, :handle)
    case request_handler do
      ^name ->
        response_type = find_response_type(env, body)
        if response_type != nil do
          {request_tag, _} = Enum.at(args, 0)
          Module.put_attribute(env.module, :response_types, {request_tag, response_type})
        end
      _ ->
        :ok
    end
  end

  def find_response_type(env, body) do
    try do
      Macro.prewalk(body, &walk(env, &1))
      nil
    catch
      {:response_type, response_type} ->
        response_type
    end
  end

  def walk(env, ast) do
    case ast do
      {{:., _, [path, :reply]}, _, _} = reply_call ->
        case Macro.expand(path, env) do
          Stage4.TypedServer ->
            get_response_type_from_typed_call(env, Macro.decompose_call(reply_call))
          other ->
            :ok
        end
        reply_call
      not_a_call ->
        not_a_call
    end
  end

  def get_response_type_from_typed_call(env, {_, _, [_, _, type] = _args} = call) do
    throw({:response_type, type})
  end
end

defmodule Stage4.TypedServer do
  defmacro __using__(_) do
    quote do
      Module.register_attribute(__MODULE__, :response_types, accumulate: true)
      @before_compile Stage4.TypedServer.CompileHooks
      @on_definition Stage4.TypedServer.CompileHooks
    end
  end

  defmacro reply(client, reply, type) do
    quote do
      reply = unquote(reply)
      annotate_type(reply, unquote(type))
      GenServer.reply(unquote(client), reply)
    end
  end
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
  ##   recompile(); GradualizerEx.type_check_file(:code.which( Test.TypedGenServer.Stage4.Server ), [:infer])

  @spec test :: any()
  def test do
    {:ok, srv} = Server.start_link()
    pid = self()
    "payload" = Server.echo(srv, "payload")
    ## This won't typecheck, since Server.echo only accepts Server.t(), that is our Server pids
    #"payload" = Server.echo(pid, "payload")
  end
end
