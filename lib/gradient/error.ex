defmodule Gradient.Error do
  @moduledoc ~S"""
  Provides error kind information and logic for ignoring errors.
  """

  require Logger

  @type kind ::
          :argument_length_mismatch
          | :bad_type_annotation
          | :call_undef
          | :form_check_timeout
          | :illegal_map_type
          | :nonexhaustive
          | {:not_exported, :remote_type}
          | {:spec_error, spec_kind()}
          | {:type_error, type_kind()}
          | {:undef, undef_kind()}

  @type spec_kind ::
          :mixed_specs
          | :wrong_spec_name

  @type type_kind ::
          :arith_error
          | :badkey
          | :call_arity
          | :call_intersect
          | :check_clauses
          | :cons_pat
          | :cyclic_type_vars
          | :expected_fun_type
          | :int_error
          | :list
          | :mismatch
          | :no_type_match_intersection
          | :non_number_argument_to_minus
          | :non_number_argument_to_plus
          | :op_type_too_precise
          | :operator_pattern
          | :pattern
          | :receive_after
          | :record_pattern
          | :rel_error
          | :relop
          | :unary_error
          | :unreachable_clause

  @type undef_kind ::
          :record
          | :record_field
          | :remote_type
          | :user_type

  @typedoc """
  In addition to the error kinds defined in `kind()`,
  ignores can also target entity error groups (e.g. `:type_error`),
  and also `:unknown`, in case an error is not identified.
  """
  @type ignored_kind ::
          kind()
          | :not_exported
          | :spec_error
          | :type_error
          | :undef
          | :unknown

  @typep ignore_rule ::
           {:ignore_file, file :: charlist()}
           | {:ignore_kind, ignored_kind()}
           | {:ignore_file_kind, file :: charlist(), ignored_kind()}
           | {:ignore_file_line, file :: charlist(), :erl_anno.line()}
           | {:ignore_file_line_kind, file :: charlist(), :erl_anno.line(), ignored_kind()}

  @typedoc """
  Ignores all errors in a given file.

  Example: `"lib/example/module.ex"`
  """
  @type ignored_file :: String.t()

  @typedoc """
  Ignores all errors in a given file and line.

  Example: `"lib/example/module.ex:12"`
  """
  @type ignored_file_line :: String.t()

  @typedoc """
  `.gradient_ignore.exs` contains a list of
  ignore values following this type definition.

  ```
  [
    # Ignores errors in the whole file
    "lib/ecto/changeset.ex",

    # Ignores errors in a specific line in a file
    "lib/ecto/schema.ex:55",

    # Ignores an error kind in a file
    {"lib/ecto/changeset.ex", {:spec_error, :mixed_specs}},

    # Ignores an error kind in a specific line
    {"lib/ecto/changeset.ex:55", {:spec_error, :mixed_specs}},

    # Ignores an error kind in all files
    {:spec_error, :mixed_specs},
  ]
  ```

  The kind can be any of `ignored_kind()`.
  """
  @type ignore ::
          ignored_file()
          | ignored_file_line()
          | {ignored_file(), line :: non_neg_integer()}
          | {ignored_file() | ignored_file_line(), ignored_kind()}
          | ignored_kind()

  defguardp is_file(file) when is_binary(file) and byte_size(file) > 0
  defguardp is_line(line) when is_integer(line) and line >= 0

  @doc """
  Returns a subset of the given `errors` list, considering
  any ignores provided through `opts[:ignores]`.
  """
  @spec reject_ignored_errors([error], Keyword.t()) :: [error] when error: tuple()
  def reject_ignored_errors(errors, opts)

  def reject_ignored_errors([], _opts), do: []

  def reject_ignored_errors(errors, opts) do
    opts
    |> ignores_option()
    |> parse_applicable_ignores()
    |> case do
      [] ->
        errors

      [_ | _] = ignores ->
        Enum.reject(errors, &ignore?(&1, ignores))
    end
  end

  @doc """
  Returns the kind of given `error`, or `:unknown`,
  if error kind could not be detected.
  """
  @spec kind(tuple()) :: kind() | :unknown
  def kind(error)

  def kind({filename, error}) when is_list(filename) do
    kind(error)
  end

  def kind({:argument_length_mismatch, _anno, _len_ty, _len_args}) do
    :argument_length_mismatch
  end

  def kind({:bad_type_annotation, _type_lit}) do
    :bad_type_annotation
  end

  def kind({:call_undef, _anno, _module, _func, _arity}) do
    :call_undef
  end

  def kind({:form_check_timeout, _form}) do
    :form_check_timeout
  end

  def kind({:illegal_map_type, _type}) do
    :illegal_map_type
  end

  def kind({:nonexhaustive, _anno, _example}) do
    :nonexhaustive
  end

  def kind({:not_exported, :remote_type, _anno, _mfa}) do
    {:not_exported, :remote_type}
  end

  def kind({:spec_error, type, _anno, _name, _arity})
      when type in [:mixed_specs, :wrong_spec_name] do
    {:spec_error, type}
  end

  def kind({:type_error, :arith_error, _arith_op, _anno, _ty}) do
    {:type_error, :arith_error}
  end

  def kind({:type_error, :arith_error, _arith_op, _anno, _ty1, _ty2}) do
    {:type_error, :arith_error}
  end

  def kind({:type_error, :badkey, _key_expr, _map_type}) do
    {:type_error, :badkey}
  end

  def kind({:type_error, :call_arity, _anno, _fun, _ty_arity, _call_arity}) do
    {:type_error, :call_arity}
  end

  def kind({:type_error, :call_intersect, _anno, _fun_ty, _name}) do
    {:type_error, :call_intersect}
  end

  def kind({:type_error, :cyclic_type_vars, _anno, _ty, _xs}) do
    {:type_error, :cyclic_type_vars}
  end

  def kind({:type_error, :cons_pat, _anno, _cons, _ty}) do
    {:type_error, :cons_pat}
  end

  def kind({:type_error, :expected_fun_type, _anno, _fun, _fun_ty}) do
    {:type_error, :expected_fun_type}
  end

  def kind({:type_error, :int_error, _arith_op, _anno, _ty1, _ty2}) do
    {:type_error, :int_error}
  end

  def kind({:type_error, :list, _anno, _ty1, _ty}) do
    {:type_error, :list}
  end

  def kind({:type_error, :list, _anno, _ty}) do
    {:type_error, :list}
  end

  def kind({:type_error, :mismatch, _ty, _expr}) do
    {:type_error, :mismatch}
  end

  def kind({:type_error, :no_type_match_intersection, _anno, _fun, _fun_ty}) do
    {:type_error, :no_type_match_intersection}
  end

  def kind({:type_error, :non_number_argument_to_plus, _anno, _ty}) do
    {:type_error, :non_number_argument_to_plus}
  end

  def kind({:type_error, :non_number_argument_to_minus, _anno, _ty}) do
    {:type_error, :non_number_argument_to_minus}
  end

  def kind({:type_error, :op_type_too_precise, _op, _anno, _ty}) do
    {:type_error, :op_type_too_precise}
  end

  def kind({:type_error, :operator_pattern, _pat, _ty}) do
    {:type_error, :operator_pattern}
  end

  def kind({:type_error, :pattern, _anno, _pat, _ty}) do
    {:type_error, :pattern}
  end

  def kind({:type_error, :receive_after, _anno, _ty_clauses, _ty_block}) do
    {:type_error, :receive_after}
  end

  def kind({:type_error, :record_pattern, _anno, _record, _ty}) do
    {:type_error, :record_pattern}
  end

  def kind({:type_error, :rel_error, _logic_op, _anno, _ty1, _ty2}) do
    {:type_error, :rel_error}
  end

  def kind({:type_error, :relop, _rel_op, _anno, _ty1, _ty2}) do
    {:type_error, :relop}
  end

  def kind({:type_error, :unary_error, _op, _anno, _target_ty, _ty}) do
    {:type_error, :unary_error}
  end

  def kind({:type_error, :unreachable_clause, _anno}) do
    {:type_error, :unreachable_clause}
  end

  def kind({:type_error, a, b, c})
      when is_tuple(a) and is_tuple(b) and is_tuple(c) do
    {:type_error, :mismatch}
  end

  def kind({:undef, type, _anno, _other})
      when type in [:record, :record_field, :user_type, :remote_type] do
    {:undef, type}
  end

  def kind({:undef, :record_field, _field_name}) do
    {:undef, :record_field}
  end

  def kind(_other), do: :unknown

  @doc """
  Returns the line of given `error`, or `nil`,
  if line could not be detected.
  """
  @spec line(error :: tuple()) :: nil | :erl_anno.line()
  def line(error)

  def line({filename, error}) when is_list(filename) and is_tuple(error) do
    line(error)
  end

  def line({:argument_length_mismatch, anno, _, _}), do: gradualizer_line(anno)
  def line({:call_undef, anno, _, _, _}), do: gradualizer_line(anno)
  def line({:nonexhaustive, anno, _}), do: gradualizer_line(anno)
  def line({:not_exported, _, anno, _}), do: gradualizer_line(anno)
  def line({:spec_error, _, anno, _, _}), do: gradualizer_line(anno)
  def line({:type_error, :arith_error, _, anno, _}), do: gradualizer_line(anno)
  def line({:type_error, :arith_error, _, anno, _, _}), do: gradualizer_line(anno)
  def line({:type_error, :call_arity, anno, _, _, _}), do: gradualizer_line(anno)
  def line({:type_error, :call_intersect, anno, _, _}), do: gradualizer_line(anno)
  def line({:type_error, :cyclic_type_vars, anno, _, _}), do: gradualizer_line(anno)
  def line({:type_error, :cons_pat, anno, _, _}), do: gradualizer_line(anno)
  def line({:type_error, :expected_fun_type, anno, _, _}), do: gradualizer_line(anno)
  def line({:type_error, :int_error, _, anno, _, _}), do: gradualizer_line(anno)
  def line({:type_error, :list, anno, _}), do: gradualizer_line(anno)
  def line({:type_error, :list, anno, _, _}), do: gradualizer_line(anno)
  def line({:type_error, :no_type_match_intersection, anno, _, _}), do: gradualizer_line(anno)
  def line({:type_error, :non_number_argument_to_plus, anno, _}), do: gradualizer_line(anno)
  def line({:type_error, :non_number_argument_to_minus, anno, _}), do: gradualizer_line(anno)
  def line({:type_error, :receive_after, anno, _, _}), do: gradualizer_line(anno)
  def line({:type_error, :record_pattern, anno, _, _}), do: gradualizer_line(anno)
  def line({:type_error, :rel_error, _, anno, _, _}), do: gradualizer_line(anno)
  def line({:type_error, :relop, _, anno, _, _}), do: gradualizer_line(anno)
  def line({:type_error, {_, anno, _}, _, _}), do: gradualizer_line(anno)
  def line({:type_error, {_, anno, _, _}, _, _}), do: gradualizer_line(anno)

  def line({:type_error, expression, _actual, _expected})
      when is_tuple(expression) do
    gradualizer_line(expression)
  end

  def line({:undef, _, anno, _}), do: gradualizer_line(anno)

  def line(_), do: nil

  defp gradualizer_line(anno_or_expr) do
    anno_or_expr
    |> :gradualizer_fmt.format_location(:brief)
    |> List.first()
    |> case do
      [_ | _] = line ->
        :erlang.list_to_integer(line)

      _ ->
        nil
    end
  end

  @spec ignore?(error :: tuple(), [ignore_rule(), ...]) :: boolean()
  defp ignore?({path, error}, [_ | _] = ignores)
       when is_binary(path) and is_tuple(error) do
    ignore?({to_charlist(path), error}, ignores)
  end

  defp ignore?({filename, error}, [_ | _] = ignores)
       when is_list(filename) and is_tuple(error) do
    kind = kind(error)
    Enum.any?(ignores, &ignore?(&1, {filename, error}, kind))
  end

  @spec ignore?(
          ignore_rule(),
          {file :: charlist(), error :: tuple()},
          kind() | :unknown
        ) :: boolean()
  defp ignore?({:ignore_file, file}, {file, _error}, _kind), do: true
  defp ignore?({:ignore_kind, kind}, {_file, _error}, {kind, _}), do: true
  defp ignore?({:ignore_kind, kind}, {_file, _error}, kind), do: true
  defp ignore?({:ignore_file_kind, file, kind}, {file, _error}, {kind, _}), do: true
  defp ignore?({:ignore_file_kind, file, kind}, {file, _error}, kind), do: true

  defp ignore?({:ignore_file_line, file, line}, {file, error}, _kind) do
    line(error) == line
  end

  defp ignore?({:ignore_file_line_kind, file, line, kind}, {file, error}, {kind, _}) do
    line(error) == line
  end

  defp ignore?({:ignore_file_line_kind, file, line, kind}, {file, error}, kind) do
    line(error) == line
  end

  defp ignore?(_ignore, _file_error, _kind), do: false

  @spec ignores_option(Keyword.t()) :: [ignore() | any()]
  defp ignores_option(opts) do
    case opts[:ignores] do
      nil ->
        []

      ignores when is_list(ignores) ->
        ignores
    end
  end

  @spec parse_applicable_ignores([ignore() | any()]) :: [ignore_rule()]
  defp parse_applicable_ignores(ignores) when is_list(ignores) do
    ignores
    |> Enum.map(fn
      {file, line} when is_file(file) and is_line(line) ->
        {:ignore_file_line, to_charlist(file), line}

      {value, kind_atom} when is_binary(value) and is_atom(kind_atom) ->
        case file_or_file_line(value) do
          nil ->
            nil

          {file, line} ->
            {:ignore_file_line_kind, file, line, kind_atom}

          file ->
            {:ignore_file_kind, file, kind_atom}
        end

      {value, {kind_meta, kind_detail}}
      when is_binary(value) and is_atom(kind_meta) and is_atom(kind_detail) ->
        case file_or_file_line(value) do
          nil ->
            nil

          {file, line} ->
            {:ignore_file_line_kind, file, line, {kind_meta, kind_detail}}

          file ->
            {:ignore_file_kind, file, {kind_meta, kind_detail}}
        end

      value when is_binary(value) ->
        case file_or_file_line(value) do
          nil ->
            nil

          {file, line} ->
            {:ignore_file_line, file, line}

          file ->
            {:ignore_file, file}
        end

      kind_atom when is_atom(kind_atom) ->
        {:ignore_kind, kind_atom}

      {kind_meta, kind_detail} when is_atom(kind_meta) and is_atom(kind_detail) ->
        {:ignore_kind, {kind_meta, kind_detail}}

      _ ->
        nil
    end)
    |> Enum.filter(& &1)
  end

  @spec file_or_file_line(String.t()) ::
          nil
          | (filename :: charlist())
          | {filename :: charlist(), line :: :erl_anno.line()}
  defp file_or_file_line(value) when is_binary(value) do
    case String.split(value, ":") do
      [file, line] when is_file(file) ->
        case Integer.parse(line) do
          {x, ""} when is_integer(x) and x >= 0 ->
            {to_charlist(file), x}

          _ ->
            nil
        end

      [file] when is_file(file) ->
        to_charlist(file)

      _ ->
        nil
    end
  end
end
