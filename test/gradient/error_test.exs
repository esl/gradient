defmodule Gradient.ErrorTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO
  alias Gradient.Error

  ## Kinds missing examples:
  #
  # - argument_length_mismatch
  # - bad_type_annotation
  # - form_check_timeout
  # - illegal_map_type
  # - nonexhaustive
  # - {not_exported, remote_type}
  # - {type_error, badkey}
  # - {type_error, call_arity}
  # - {type_error, call_intersect}
  # - {type_error, check_clauses}
  # - {type_error, cons_pat}
  # - {type_error, cyclic_type_vars}
  # - {type_error, expected_fun_type}
  # - {type_error, int_error}
  # - {type_error, list}
  # - {type_error, no_type_match_intersection}
  # - {type_error, non_number_argument_to_minus}
  # - {type_error, non_number_argument_to_plus}
  # - {type_error, op_type_too_precise}
  # - {type_error, operator_pattern}
  # - {type_error, pattern}
  # - {type_error, receive_after}
  # - {type_error, record_pattern}
  # - {type_error, rel_error}
  # - {type_error, relop}
  # - {type_error, unary_error}
  # - {undef, record}
  # - {undef, record_field}
  # - {undef, remote_type}
  # - {undef, user_type}

  @examples [
    basic: [],
    "basic/atom": [],
    "basic/binary": [],
    "basic/char": [],
    "basic/charlist": [],
    "basic/float": [],
    "basic/int": [],
    "basic/string": [],
    call: [],
    call_remote_exception: [
      {8, :call_undef}
    ],
    "conditional/case": [],
    "conditional/cond": [],
    "conditional/guards": [],
    "conditional/if": [],
    "conditional/unless": [],
    "conditional/with": [
      {12, {:type_error, :mismatch}}
    ],
    list: [],
    list_comprehension: [],
    map: [],
    pipe_op: [],
    receive: [],
    "record/record": [],
    simple_app: [
      {31, {:type_error, :mismatch}}
    ],
    simple_range: [],
    spec_correct: [],
    spec_default_args: [],
    spec_mixed: [
      {3, {:spec_error, :mixed_specs}},
      {3, {:spec_error, :wrong_spec_name}},
    ],
    spec_wrong_name: [
      {3, {:type_error, :arith_error}},
      {5, {:spec_error, :wrong_spec_name}},
      {8, {:type_error, :mismatch}},
      {11, {:spec_error, :wrong_spec_name}}
    ],
    spec_wrong_args_arity: [
      {2, {:spec_error, :wrong_spec_name}}
    ],
    string_example: [
      {18, {:type_error, :mismatch}}
    ],
    "struct/struct": [],
    try: [
      {44, {:type_error, :mismatch}}
    ],
    tuple: [],
    "type/list_infer": [],
    "type/record": [
      {8, {:type_error, :mismatch}},
      {11, {:type_error, :mismatch}},
      {14, {:type_error, :mismatch}}
    ],
    "type/s_wrong_ret": [
      {3, {:type_error, :mismatch}},
      {6, {:type_error, :mismatch}}
    ],
    "type/wrong_ret": [
      {3, {:type_error, :mismatch}},
      {6, {:type_error, :mismatch}},
      {9, {:type_error, :mismatch}},
      {15, {:type_error, :mismatch}},
      {18, {:type_error, :mismatch}},
      {21, {:type_error, :mismatch}},
      {24, {:type_error, :mismatch}},
      {27, {:type_error, :mismatch}},
      {31, {:type_error, :mismatch}},
      {35, {:type_error, :mismatch}},
      {41, {:type_error, :mismatch}},
      {45, {:type_error, :mismatch}},
      {50, {:type_error, :mismatch}},
      {53, {:type_error, :mismatch}},
      {56, {:type_error, :mismatch}},
      {59, {:type_error, :mismatch}},
      {62, {:type_error, :mismatch}},
      {65, {:type_error, :mismatch}},
      {68, {:type_error, :mismatch}},
      {71, {:type_error, :mismatch}},
      {74, {:type_error, :mismatch}},
      {77, {:type_error, :mismatch}},
      {80, :unknown}
    ],
    typespec: [
      {6, {:undef, :remote_type}},
      {12, {:undef, :remote_type}},
      {18, {:undef, :remote_type}}
    ],
    typespec_beh: [],
    typespec_when: []
  ]

  test "kinds match examples" do
    for {example, expected_result} <- @examples do
      actual_result = example |> path() |> errors() |> compact()
      assert {_, ^actual_result} = {example, expected_result}
    end
  end

  describe "reject_ignored_errors/2" do
    test "ignores nothing when there's no opts[:ignores]" do
      path = path(:typespec)
      assert [_ | _] = errors = errors(path)
      assert ^errors = Error.reject_ignored_errors(errors, [])
    end

    test "ignores all errors of a file" do
      path = path(:typespec)
      assert [_ | _] = errors = errors(path)
      assert [] = reject(errors, path)
    end

    test "ignores errors on a file line" do
      path = path(:typespec)
      errors = errors(path)

      assert [6, 12, 18] = error_lines(errors)

      assert [6, 18] = errors |> reject({path, 12}) |> error_lines()
      assert [6, 12] = errors |> reject("#{path}:18") |> error_lines()
    end

    test "ignores errors by kind" do
      path = path(:spec_wrong_name)
      errors = errors(path)

      reject_compact = &compact(reject(errors, &1))

      assert compact(errors) == [
               {3, {:type_error, :arith_error}},
               {5, {:spec_error, :wrong_spec_name}},
               {8, {:type_error, :mismatch}},
               {11, {:spec_error, :wrong_spec_name}}
             ]

      # ignoring all occurrences of an error
      assert reject_compact.({:spec_error, :wrong_spec_name}) == [
               {3, {:type_error, :arith_error}},
               {8, {:type_error, :mismatch}}
             ]

      # ignoring all occurrences of another error
      assert reject_compact.({:type_error, :arith_error}) == [
               {5, {:spec_error, :wrong_spec_name}},
               {8, {:type_error, :mismatch}},
               {11, {:spec_error, :wrong_spec_name}}
             ]

      # ignoring all occurrences of error group
      assert reject_compact.(:type_error) == [
               {5, {:spec_error, :wrong_spec_name}},
               {11, {:spec_error, :wrong_spec_name}}
             ]

      # ignoring all occurrences of an error on a file
      assert reject_compact.({path, {:spec_error, :wrong_spec_name}}) == [
               {3, {:type_error, :arith_error}},
               {8, {:type_error, :mismatch}}
             ]

      # ignoring all occurrences of another error on a file
      assert reject_compact.({path, {:type_error, :arith_error}}) == [
               {5, {:spec_error, :wrong_spec_name}},
               {8, {:type_error, :mismatch}},
               {11, {:spec_error, :wrong_spec_name}}
             ]

      # ignoring all occurrences of error group on a file
      assert reject_compact.({path, :type_error}) == [
               {5, {:spec_error, :wrong_spec_name}},
               {11, {:spec_error, :wrong_spec_name}}
             ]

      # ignoring all occurrences of an error on a file line
      assert reject_compact.({"#{path}:5", {:spec_error, :wrong_spec_name}}) == [
               {3, {:type_error, :arith_error}},
               {8, {:type_error, :mismatch}},
               {11, {:spec_error, :wrong_spec_name}}
             ]

      # ignoring all occurrences of an error group on a file line
      assert reject_compact.({"#{path}:3", :type_error}) == [
               {5, {:spec_error, :wrong_spec_name}},
               {8, {:type_error, :mismatch}},
               {11, {:spec_error, :wrong_spec_name}}
             ]
    end
  end

  defp compact(errors) do
    errors
    |> Enum.map(&{Error.line(&1), Error.kind(&1)})
    |> Enum.sort_by(&elem(&1, 0))
  end

  defp error_lines(errors) do
    errors |> Enum.map(&Error.line/1) |> Enum.sort()
  end

  defp reject(errors, ignore) do
    Error.reject_ignored_errors(errors, ignores: [ignore])
  end

  defp path(example) do
    Path.join(["test", "examples", "#{example}.ex"])
  end

  defp errors(path) do
    pid = self()
    ref = make_ref()

    _ =
      capture_io(fn ->
        capture_io(:stderr, fn ->
          errors =
            case Gradient.type_check_file(path) do
              [:ok] ->
                []

              [{:error, errors}] when is_list(errors) ->
                errors
            end

          send(pid, {:errors, ref, errors})
        end)
      end)

    receive do
      {:errors, ^ref, errors} ->
        errors
    end
  end
end
