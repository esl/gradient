defmodule Gradient.TypedServer.CompileHooks do
  @moduledoc false

  defmacro __before_compile__(env) do
    response_types = Module.get_attribute(env.module, :response_types)
    # IO.inspect(response_types, label: "response types")
    for {request_tag, response_type} <- response_types do
      name = Macro.escape(:"call_#{request_tag}")

      quote do
        @spec unquote(name)(t(), any) :: unquote(response_type)
        defp unquote(name)(pid, arg) do
          GenServer.call(pid, {unquote(request_tag), arg})
        end
      end
    end
  end

  def __on_definition__(env, _kind, name, args, _guards, body) do
    # if name == :handle do
    #  # IO.inspect({name, env}, limit: :infinity)
    #  #{env.module, Module.get_attribute(env.module, :spec)} |> IO.inspect()
    # end

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
          Gradient.TypedServer ->
            get_response_type_from_typed_call(env, Macro.decompose_call(reply_call))

          _other ->
            :ok
        end

        reply_call

      not_a_call ->
        not_a_call
    end
  end

  def get_response_type_from_typed_call(_env, {_, _, [_, _, type] = _args} = _call) do
    throw({:response_type, type})
  end
end
