defmodule Gradient.DebugTest do
  use ExUnit.Case

  alias Gradient.Debug
  import ExUnit.CaptureIO

  @examples_build_path "test/examples/_build"

  defp build_beam_path(beam_file) do
    @examples_build_path
    |> Path.join(beam_file)
    |> String.to_charlist()
  end

  describe "elixir_ast/1" do
    test "returns elixir AST" do
      beam_path = build_beam_path("Elixir.Basic.beam")

      assert {:ok,
              %{
                attributes: [],
                compile_opts: [],
                definitions: [
                  {{:string, 0}, :def, [line: 4], [{[line: 4], [], [], "2"}]},
                  {{:int, 0}, :def, [line: 2], [{[line: 2], [], [], 1}]},
                  {{:float, 0}, :def, [line: 3], [{[line: 3], [], [], 1.5}]},
                  {{:charlist, 0}, :def, [line: 5], [{[line: 5], [], [], '3'}]},
                  {{:char, 0}, :def, [line: 6], [{[line: 6], [], [], 99}]}
                ],
                deprecated: [],
                file: _file,
                is_behaviour: false,
                line: 1,
                module: Basic,
                relative_file: "test/examples/basic.ex",
                struct: nil,
                unreachable: []
              }} = Debug.elixir_ast(beam_path)
    end
  end

  describe "erlang_ast/1" do
    test "returns erlang AST" do
      beam_path = build_beam_path("Elixir.Basic.beam")

      assert {:ok, forms} = Debug.erlang_ast(beam_path)

      function_defs =
        forms
        |> Enum.filter(&(elem(&1, 0) == :function))
        |> Enum.reject(&(elem(&1, 2) == :__info__))
        |> Enum.sort_by(fn {:function, line, _, _, _} -> line end)

      assert function_defs ==
               [
                 {:function, 2, :int, 0, [{:clause, 2, [], [], [{:integer, 2, 1}]}]},
                 {:function, 3, :float, 0, [{:clause, 3, [], [], [{:float, 3, 1.5}]}]},
                 {:function, 4, :string, 0,
                  [
                    {:clause, 4, [], [],
                     [{:bin, 4, [{:bin_element, 4, {:string, 4, '2'}, :default, :default}]}]}
                  ]},
                 {:function, 5, :charlist, 0,
                  [{:clause, 5, [], [], [{:cons, 5, {:integer, 5, 51}, {nil, 5}}]}]},
                 {:function, 6, :char, 0, [{:clause, 6, [], [], [{:integer, 6, 99}]}]}
               ]
    end
  end

  describe "print_erlang/1" do
    test "prints erlang representation of module" do
      beam_path = build_beam_path("Elixir.Basic.beam")

      output_lines =
        capture_io(fn -> Debug.print_erlang(beam_path) end)
        |> String.split("\n")

      assert "-file(\"test/examples/basic.ex\", 1)." in output_lines
      assert "-module('Elixir.Basic')." in output_lines
      assert "char() -> 99." in output_lines
      assert "int() -> 1." in output_lines
    end
  end

  describe "print_elixir/1" do
    test "prints elixir specs and functions" do
      beam_path = build_beam_path("Elixir.SWrongRet.beam")

      output_lines =
        capture_io(fn -> Debug.print_elixir(beam_path) end)
        |> String.split("\n")
        |> Enum.map(&String.trim/1)

      assert "@spec ret_wrong_atom() :: atom()" in output_lines
      assert "def ret_wrong_atom() do" in output_lines

      assert "@spec ret_wrong_atom2() :: atom()" in output_lines
      assert "def ret_wrong_atom2() do" in output_lines
    end

    test "prints elixir types" do
      beam_path = build_beam_path("Elixir.Typespec.beam")

      output_lines =
        capture_io(fn -> Debug.print_elixir(beam_path) end)
        |> String.split("\n")
        |> Enum.map(&String.trim/1)

      assert "@type mylist :: list(t)" in output_lines
    end
  end
end
