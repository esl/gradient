defmodule Gradient.AstSpecifierTest do
  use ExUnit.Case
  doctest Gradient.AstSpecifier

  alias Gradient.AstSpecifier
  alias Gradient.AstData

  import Gradient.TestHelpers

  setup_all state do
    {:ok, state}
  end

  describe "specifying expression" do
    for {name, args, expected} <- AstData.ast_data() do
      test "#{name}" do
        {ast, tokens, opts} = unquote(Macro.escape(args))
        expected = AstData.normalize_expression(unquote(Macro.escape(expected)))

        actual = AstData.normalize_expression(elem(AstSpecifier.mapper(ast, tokens, opts), 0))

        assert expected == actual
      end
    end
  end

  describe "run_mappers/2" do
    test "messy test on simple_app" do
      {tokens, ast} = example_data()
      new_ast = AstSpecifier.run_mappers(ast, tokens)

      assert is_list(new_ast)
    end

    test "integer" do
      {tokens, ast} = load("Elixir.Basic.Int.beam", "basic/int.ex")

      [block, inline | _] = AstSpecifier.run_mappers(ast, tokens) |> Enum.reverse()

      assert {:function, 2, :int, 0, [{:clause, 2, [], [], [{:integer, [location: {2, 16}, end_location: {2, 17}], 1}]}]} = inline

      assert {:function, 4, :int_block, 0, [{:clause, 4, [], [], [{:integer, 5, 2}]}]} = block
    end

    test "float" do
      {tokens, ast} = load("Elixir.Basic.Float.beam", "basic/float.ex")

      [block, inline | _] = AstSpecifier.run_mappers(ast, tokens) |> Enum.reverse()
      assert {:function, 2, :float, 0, [{:clause, 2, [], [], [{:float, [location: {2, 18}, end_location: {2, 22}], 0.12}]}]} = inline

      assert {:function, 4, :float_block, 0, [{:clause, 4, [], [], [{:float, 5, 0.12}]}]} = block
    end

    test "atom" do
      {tokens, ast} = load("Elixir.Basic.Atom.beam", "basic/atom.ex")

      [block, inline | _] = AstSpecifier.run_mappers(ast, tokens) |> Enum.reverse()

      assert {:function, 2, :atom, 0, [{:clause, 2, [], [], [{:atom, [location: {2, 17}, end_location: {2, 19}], :ok}]}]} = inline

      assert {:function, 4, :atom_block, 0, [{:clause, 4, [], [], [{:atom, [location: {5, 5}, end_location: {5, 7}], :ok}]}]} = block
    end

    test "char" do
      {tokens, ast} = load("Elixir.Basic.Char.beam", "basic/char.ex")

      [block, inline | _] = AstSpecifier.run_mappers(ast, tokens) |> Enum.reverse()

      assert {:function, 2, :char, 0, [{:clause, 2, [], [], [{:integer, 2, 99}]}]} = inline

      assert {:function, 4, :char_block, 0, [{:clause, 4, [], [], [{:integer, 5, 99}]}]} = block
    end

    test "charlist" do
      {tokens, ast} = load("Elixir.Basic.Charlist.beam", "basic/charlist.ex")

      [block, inline | _] = AstSpecifier.run_mappers(ast, tokens) |> Enum.reverse()

      # TODO propagate location to each charlist element
      assert {:function, 2, :charlist, 0,
              [
                {:clause, 2, [], [],
                 [
                   {:cons, 2, {:integer, 2, 97},
                    {:cons, 2, {:integer, 2, 98}, {:cons, 2, {:integer, 2, 99}, {nil, 2}}}}
                 ]}
              ]} = inline

      assert {:function, 4, :charlist_block, 0,
              [
                {:clause, 4, [], [],
                 [
                   {:cons, 5, {:integer, 5, 97},
                    {:cons, 5, {:integer, 5, 98}, {:cons, 5, {:integer, 5, 99}, {nil, 5}}}}
                 ]}
              ]} = block
    end

    test "string" do
      {tokens, ast} = load("Elixir.Basic.String.beam", "basic/string.ex")

      [block, inline | _] = AstSpecifier.run_mappers(ast, tokens) |> Enum.reverse()

      assert {:function, 2, :string, 0,
              [
                {:clause, 2, [], [],
                 [{:bin, 2, [{:bin_element, 2, {:string, 2, 'abc'}, :default, :default}]}]}
              ]} = inline

      assert {:function, 4, :string_block, 0,
              [
                {:clause, 4, [], [],
                 [{:bin, 5, [{:bin_element, 5, {:string, 5, 'abc'}, :default, :default}]}]}
              ]} = block
    end

    test "tuple" do
      {tokens, ast} = load("Elixir.TupleEx.beam", "tuple.ex")

      [tuple_in_str2, tuple_in_str, tuple_in_list, _list_in_tuple, tuple | _] =
        AstSpecifier.run_mappers(ast, tokens) |> Enum.reverse()

      # FIXME
      assert {:function, 18, :tuple_in_str2, 0,
              [
                {:clause, 18, [], [],
                 [
                   {:match, 19, {:var, 19, :_msg@1},
                    {:bin, 20,
                     [
                       {:bin_element, 20, {:string, 20, '\nElixir formatter not exist for '},
                        :default, :default},
                       {:bin_element, 20,
                        {:call, 20, {:remote, 20, {:atom, 20, Kernel}, {:atom, 20, :inspect}},
                         [
                           {:tuple, 20, []},
                           {:cons, 20, {:tuple, 20, [{:atom, 20, :pretty}, {:atom, 20, true}]},
                            {:cons, 20,
                             {:tuple, 20, [{:atom, 20, :limit}, {:atom, 20, :infinity}]},
                             {nil, 20}}}
                         ]}, :default, [:binary]},
                       {:bin_element, 20, {:string, 20, ' using default \n'}, :default, :default}
                     ]}},
                   {:call, 22, {:remote, 22, {:atom, 22, String}, {:atom, 22, :to_charlist}},
                    [
                      {:bin, 22,
                       [
                         {:bin_element, 22,
                          {:call, 22,
                           {:remote, 22, {:atom, 22, IO.ANSI}, {:atom, 22, :light_yellow}}, []},
                          :default, [:binary]},
                         {:bin_element, 22, {:var, 22, :_msg@1}, :default, [:binary]},
                         {:bin_element, 22,
                          {:call, 22, {:remote, 22, {:atom, 22, IO.ANSI}, {:atom, 22, :reset}},
                           []}, :default, [:binary]}
                       ]}
                    ]}
                 ]}
              ]} = tuple_in_str2

      assert {:function, 14, :tuple_in_str, 0,
              [
                {:clause, 14, [], [],
                 [
                   {:bin, 15,
                    [
                      {:bin_element, 15, {:string, 15, 'abc '}, :default, :default},
                      {:bin_element, 15,
                       {:call, 15, {:remote, 15, {:atom, 15, Kernel}, {:atom, 15, :inspect}},
                        [
                          {:atom, 15, :abc},
                          {:cons, 15, {:tuple, 15, [{:atom, 15, :limit}, {:atom, 15, :infinity}]},
                           {:cons, 15,
                            {:tuple, 15,
                             [
                               {:atom, 15, :label},
                               {:bin, 15,
                                [
                                  {:bin_element, 15, {:string, 15, 'abc '}, :default, :default},
                                  {:bin_element, 15,
                                   {:case, [generated: true, location: 15], {:integer, 15, 13},
                                    [
                                      {:clause, [generated: true, location: 15],
                                       [{:var, [generated: true, location: 15], :_@1}],
                                       [
                                         [
                                           {:call, [generated: true, location: 15],
                                            {:remote, [generated: true, location: 15],
                                             {:atom, [generated: true, location: 15], :erlang},
                                             {:atom, [generated: true, location: 15], :is_binary}},
                                            [{:var, [generated: true, location: 15], :_@1}]}
                                         ]
                                       ], [{:var, [generated: true, location: 15], :_@1}]},
                                      {:clause, [generated: true, location: 15],
                                       [{:var, [generated: true, location: 15], :_@1}], [],
                                       [
                                         {:call, [generated: true, location: 15],
                                          {:remote, [generated: true, location: 15],
                                           {:atom, [generated: true, location: 15], String.Chars},
                                           {:atom, [generated: true, location: 15], :to_string}},
                                          [{:var, [generated: true, location: 15], :_@1}]}
                                       ]}
                                    ]}, :default, [:binary]}
                                ]}
                             ]}, {nil, 15}}}
                        ]}, :default, [:binary]},
                      {:bin_element, 15, {:integer, 15, 12}, :default, [:integer]}
                    ]}
                 ]}
              ]} = tuple_in_str

      assert {:function, 10, :tuple_in_list, 0,
              [
                {:clause, 10, [], [],
                 [
                   {:cons, 11, {:tuple, 11, [{:atom, 11, :a}, {:integer, 11, 12}]},
                    {:cons, 11, {:tuple, 11, [{:atom, 11, :b}, {:atom, 11, :ok}]}, {nil, 11}}}
                 ]}
              ]} = tuple_in_list

      assert {:function, 2, :tuple, 0,
              [{:clause, 2, [], [], [{:tuple, 3, [{:atom, 3, :ok}, {:integer, 3, 12}]}]}]} = tuple
    end

    test "binary" do
      {tokens, ast} = load("Elixir.Basic.Binary.beam", "basic/binary.ex")

      [complex2, complex, bin_block, bin | _] =
        AstSpecifier.run_mappers(ast, tokens)
        |> Enum.reverse()

      assert {:function, 13, :complex2, 0,
              [
                {:clause, 13, [], [],
                 [
                   {:bin, 14,
                    [
                      {:bin_element, 14, {:string, 14, 'abc '}, :default, :default},
                      {:bin_element, 14,
                       {:call, 14, {:remote, 14, {:atom, 14, Kernel}, {:atom, 14, :inspect}},
                        [{:integer, 14, 12}]}, :default, [:binary]},
                      {:bin_element, 14, {:string, 14, ' cba'}, :default, :default}
                    ]}
                 ]}
              ]} = complex2

      assert {:function, 8, :complex, 0,
              [
                {:clause, 8, [], [],
                 [
                   {:match, 9, {:var, 9, :_x@2},
                    {:fun, 9,
                     {:clauses,
                      [
                        {:clause, 9, [{:var, 9, :_x@1}], [],
                         [{:op, 9, :+, {:var, 9, :_x@1}, {:integer, 9, 1}}]}
                      ]}}},
                   {:bin, 10,
                    [
                      {:bin_element, 10, {:integer, 10, 49}, :default, [:integer]},
                      {:bin_element, 10, {:integer, 10, 48}, :default, [:integer]},
                      {:bin_element, 10, {:call, 10, {:var, 10, :_x@2}, [{:integer, 10, 50}]},
                       :default, [:integer]}
                    ]}
                 ]}
              ]} = complex

      assert {:function, 4, :bin_block, 0,
              [
                {:clause, 4, [], [],
                 [
                   {:bin, 5,
                    [
                      {:bin_element, 5, {:integer, 5, 49}, :default, [:integer]},
                      {:bin_element, 5, {:integer, 5, 48}, :default, [:integer]},
                      {:bin_element, 5, {:integer, 5, 48}, :default, [:integer]}
                    ]}
                 ]}
              ]} = bin_block

      assert {:function, 2, :bin, 0,
              [
                {:clause, 2, [], [],
                 [
                   {:bin, 2,
                    [
                      {:bin_element, 2, {:integer, 2, 49}, :default, [:integer]},
                      {:bin_element, 2, {:integer, 2, 48}, :default, [:integer]},
                      {:bin_element, 2, {:integer, 2, 48}, :default, [:integer]}
                    ]}
                 ]}
              ]} = bin
    end

    test "case conditional" do
      {tokens, ast} = load("Elixir.Conditional.Case.beam", "conditional/case.ex")

      [block, inline | _] = AstSpecifier.run_mappers(ast, tokens) |> Enum.reverse()

      assert {:function, 2, :case_, 0,
              [
                {:clause, 2, [], [],
                 [
                   {:case, 4, {:integer, 4, 5},
                    [
                      {:clause, 5, [{:integer, 5, 5}], [], [{:atom, 5, :ok}]},
                      {:clause, 6, [{:var, 6, :_}], [], [{:atom, 6, :error}]}
                    ]}
                 ]}
              ]} = inline

      assert {:function, 9, :case_block, 0,
              [
                {:clause, 9, [], [],
                 [
                   {:case, 10, {:integer, 10, 5},
                    [
                      {:clause, 11, [{:integer, 11, 5}], [], [{:atom, 11, :ok}]},
                      {:clause, 12, [{:var, 12, :_}], [], [{:atom, 12, :error}]}
                    ]}
                 ]}
              ]} = block
    end

    test "if conditional" do
      {tokens, ast} = load("Elixir.Conditional.If.beam", "conditional/if.ex")

      [block, inline, if_ | _] = AstSpecifier.run_mappers(ast, tokens) |> Enum.reverse()

      assert {:function, 12, :if_block, 0,
              [
                {:clause, 12, [], [],
                 [
                   {:case, 13, {:op, 13, :<, {:integer, 13, 1}, {:integer, 13, 5}},
                    [
                      {:clause, [generated: true, location: 13],
                       [{:atom, [generated: true, location: 13], false}], [],
                       [{:atom, 16, :error}]},
                      {:clause, [generated: true, location: 13],
                       [{:atom, [generated: true, location: 13], true}], [], [{:atom, 14, :ok}]}
                    ]}
                 ]}
              ]} = block

      assert {:function, 10, :if_inline, 0,
              [
                {:clause, 10, [], [],
                 [
                   {:case, 10, {:op, 10, :<, {:integer, 10, 1}, {:integer, 10, 5}},
                    [
                      {:clause, [generated: true, location: 10],
                       [{:atom, [generated: true, location: 10], false}], [],
                       [{:atom, 10, :error}]},
                      {:clause, [generated: true, location: 10],
                       [{:atom, [generated: true, location: 10], true}], [], [{:atom, 10, :ok}]}
                    ]}
                 ]}
              ]} = inline

      assert {:function, 2, :if_, 0,
              [
                {:clause, 2, [], [],
                 [
                   {:case, 4, {:op, 4, :<, {:integer, 4, 1}, {:integer, 4, 5}},
                    [
                      {:clause, [generated: true, location: 4],
                       [{:atom, [generated: true, location: 4], false}], [],
                       [{:atom, 7, :error}]},
                      {:clause, [generated: true, location: 4],
                       [{:atom, [generated: true, location: 4], true}], [], [{:atom, 5, :ok}]}
                    ]}
                 ]}
              ]} = if_
    end

    test "unless conditional" do
      {tokens, ast} = load("Elixir.Conditional.Unless.beam", "conditional/unless.ex")

      [block | _] = AstSpecifier.run_mappers(ast, tokens) |> Enum.reverse()

      assert {
               :function,
               2,
               :unless_block,
               0,
               [
                 {:clause, 2, [], [],
                  [
                    {:case, 3, {:atom, 3, false},
                     [
                       {:clause, [generated: true, location: 3],
                        [{:atom, [generated: true, location: 3], false}], [], [{:atom, 4, :ok}]},
                       {:clause, [generated: true, location: 3],
                        [{:atom, [generated: true, location: 3], true}], [], [{:atom, 6, :error}]}
                     ]}
                  ]}
               ]
             } = block
    end

    test "cond conditional" do
      {tokens, ast} = load("Elixir.Conditional.Cond.beam", "conditional/cond.ex")

      [block, inline | _] = AstSpecifier.run_mappers(ast, tokens) |> Enum.reverse()

      assert {:function, 2, :cond_, 1,
              [
                {:clause, 2, [{:var, 2, :_a@1}], [],
                 [
                   {:case, 4, {:op, 5, :==, {:var, 5, :_a@1}, {:atom, 5, :ok}},
                    [
                      {:clause, 5, [{:atom, 5, true}], [], [{:atom, 5, :ok}]},
                      {:clause, 6, [{:atom, 6, false}], [],
                       [
                         {:case, 6, {:op, 6, :>, {:var, 6, :_a@1}, {:integer, 6, 5}},
                          [
                            {:clause, 6, [{:atom, 6, true}], [], [{:atom, 6, :ok}]},
                            {:clause, 7, [{:atom, 7, false}], [],
                             [
                               {:case, 7, {:atom, 7, true},
                                [
                                  {:clause, 7, [{:atom, 7, true}], [], [{:atom, 7, :error}]},
                                  {:clause, [generated: true, location: 7],
                                   [{:atom, [generated: true, location: 7], false}], [],
                                   [
                                     {:call, 7,
                                      {:remote, 7, {:atom, 7, :erlang}, {:atom, 7, :error}},
                                      [{:atom, 7, :cond_clause}]}
                                   ]}
                                ]}
                             ]}
                          ]}
                       ]}
                    ]}
                 ]}
              ]} = inline

      assert {:function, 10, :cond_block, 0,
              [
                {:clause, 10, [], [],
                 [
                   {:match, 11, {:var, 11, :_a@1}, {:integer, 11, 5}},
                   {:case, 13, {:op, 14, :==, {:var, 14, :_a@1}, {:atom, 14, :ok}},
                    [
                      {:clause, 14, [{:atom, 14, true}], [], [{:atom, 14, :ok}]},
                      {:clause, 15, [{:atom, 15, false}], [],
                       [
                         {:case, 15, {:op, 15, :>, {:var, 15, :_a@1}, {:integer, 15, 5}},
                          [
                            {:clause, 15, [{:atom, 15, true}], [], [{:atom, 15, :ok}]},
                            {:clause, 16, [{:atom, 16, false}], [],
                             [
                               {:case, 16, {:atom, 16, true},
                                [
                                  {:clause, 16, [{:atom, 16, true}], [], [{:atom, 16, :error}]},
                                  {:clause, [generated: true, location: 16],
                                   [{:atom, [generated: true, location: 16], false}], [],
                                   [
                                     {:call, 16,
                                      {:remote, 16, {:atom, 16, :erlang}, {:atom, 16, :error}},
                                      [{:atom, 16, :cond_clause}]}
                                   ]}
                                ]}
                             ]}
                          ]}
                       ]}
                    ]}
                 ]}
              ]} = block
    end

    test "with conditional" do
      {tokens, ast} = load("Elixir.Conditional.With.beam", "conditional/with.ex")

      [block | _] = AstSpecifier.run_mappers(ast, tokens) |> Enum.reverse()

      assert {:function, 6, :test_with, 0,
              [
                {:clause, 6, [], [],
                 [
                   {:case, [generated: true, location: 7], {:call, 7, {:atom, 7, :ok_res}, []},
                    [
                      {:clause, 7, [{:tuple, 7, [{:atom, 7, :ok}, {:var, 7, :__a@1}]}], [],
                       [{:integer, 8, 12}]},
                      {:clause, [generated: true, location: 7], [{:var, 10, :_}], [],
                       [
                         {:block, 7,
                          [
                            {:call, 11, {:remote, 11, {:atom, 11, IO}, {:atom, 11, :puts}},
                             [
                               {:bin, 11,
                                [{:bin_element, 11, {:string, 11, 'error'}, :default, :default}]}
                             ]},
                            {:cons, 12, {:integer, 12, 49},
                             {:cons, 12, {:integer, 12, 50}, {nil, 12}}}
                          ]}
                       ]}
                    ]}
                 ]}
              ]} == block
    end

    @tag :skip
    test "basic function return" do
      ex_file = "basic.ex"
      beam_file = "Elixir.Basic.beam"
      {tokens, ast} = load(beam_file, ex_file)

      specified_ast = AstSpecifier.run_mappers(ast, tokens)
      IO.inspect(specified_ast)
      assert is_list(specified_ast)
    end
  end

  test "specify_line/2" do
    {tokens, _} = example_data()
    opts = [end_line: -1]

    assert {{:integer, [location: {21, 9}, end_location: {21, 11}], 12}, tokens} =
             AstSpecifier.specify_line({:integer, 21, 12}, tokens, opts)

    assert {{:integer, [location: {22, 5}, end_location: {22, 7}], 12}, _tokens} =
             AstSpecifier.specify_line({:integer, 20, 12}, tokens, opts)
  end

  test "cons_to_charlist/1" do
    cons =
      {:cons, 0, {:integer, 0, 49},
       {:cons, 0, {:integer, 0, 48}, {:cons, 0, {:integer, 0, 48}, {nil, 0}}}}

    assert '100' == AstSpecifier.cons_to_charlist(cons)
  end

  describe "test that prints result" do
    @tag :skip
    test "specify/1" do
      {_tokens, forms} = example_data()

      AstSpecifier.specify(forms)
      |> IO.inspect()
    end

    @tag :skip
    test "display forms" do
      {_, forms} = example_data()
      IO.inspect(forms)
    end
  end

  test "function call" do
    {tokens, ast} = load("Elixir.Call.beam", "call.ex")

    [call, _ | _] = AstSpecifier.run_mappers(ast, tokens) |> Enum.reverse()

    assert {:function, 5, :call, 0,
            [
              {:clause, 5, [], [],
               [
                 {:call, 6, {:atom, 6, :get_x},
                  [
                    {:bin, 7, [{:bin_element, 7, {:string, 7, 'ala'}, :default, :default}]},
                    {:cons, 8, {:integer, 8, 97},
                     {:cons, 8, {:integer, 8, 108}, {:cons, 8, {:integer, 8, 97}, {nil, 8}}}},
                    {:integer, 9, 12}
                  ]}
               ]}
            ]} = call
  end

  test "pipe" do
    {tokens, ast} = load("Elixir.Pipe.beam", "pipe_op.ex")

    [block | _] = AstSpecifier.run_mappers(ast, tokens) |> Enum.reverse()

    assert {:function, 2, :pipe, 0,
            [
              {:clause, 2, [], [],
               [
                 {:call, 5, {:remote, 5, {:atom, 5, :erlang}, {:atom, 5, :length}},
                  [
                    {:call, 4, {:remote, 4, {:atom, 4, Enum}, {:atom, 4, :filter}},
                     [
                       {:cons, 3, {:integer, 3, 1},
                        {:cons, 3,
                         {
                           :integer,
                           3,
                           2
                         }, {:cons, 3, {:integer, 3, 3}, {nil, 3}}}},
                       {:fun, 4,
                        {:clauses,
                         [
                           {:clause, 4, [{:var, 4, :_x@1}], [],
                            [{:op, 4, :<, {:var, 4, :_x@1}, {:integer, 4, 3}}]}
                         ]}}
                     ]}
                  ]}
               ]}
            ]} = block
  end

  test "guards" do
    {tokens, ast} = load("Elixir.Conditional.Guard.beam", "conditional/guards.ex")

    [guarded_case, guarded_fun | _] = AstSpecifier.run_mappers(ast, tokens) |> Enum.reverse()

    assert {:function, 3, :guarded_fun, 1,
            [
              {:clause, 3, [{:var, 3, :_x@1}],
               [
                 [
                   {:call, 3, {:remote, 3, {:atom, 3, :erlang}, {:atom, 3, :is_integer}},
                    [{:var, 3, :_x@1}]}
                 ],
                 [
                   {:op, 3, :andalso, {:op, 3, :>, {:var, 3, :_x@1}, {:integer, 3, 3}},
                    {:op, 3, :<, {:var, 3, :_x@1}, {:integer, 3, 6}}}
                 ]
               ], [{:atom, 3, :ok}]}
            ]} = guarded_fun

    assert {:function, 6, :guarded_case, 1,
            [
              {:clause, 6, [{:var, 6, :_x@1}], [],
               [
                 {:case, 7, {:var, 7, :_x@1},
                  [
                    {:clause, 8, [{:integer, 8, 0}], [],
                     [{:tuple, 8, [{:atom, 8, :ok}, {:integer, 8, 1}]}]},
                    {:clause, 9, [{:var, 9, :_i@1}],
                     [[{:op, 9, :>, {:var, 9, :_i@1}, {:integer, 9, 0}}]],
                     [
                       {:tuple, 9,
                        [{:atom, 9, :ok}, {:op, 9, :+, {:var, 9, :_i@1}, {:integer, 9, 1}}]}
                     ]},
                    {:clause, 10, [{:var, 10, :__otherwise@1}], [], [{:atom, 10, :error}]}
                  ]}
               ]}
            ]} = guarded_case
  end

  @tag :ex_lt_1_12
  test "range" do
    {tokens, ast} = load("Elixir.SimpleRange.beam", "simple_range.ex")

    [range | _] = AstSpecifier.run_mappers(ast, tokens) |> Enum.reverse()

    assert {:function, 2, :range, 0,
            [
              {:clause, 2, [], [],
               [
                 {:map, 3,
                  [
                    {:map_field_assoc, 3, {:atom, 3, :__struct__}, {:atom, 3, Range}},
                    {:map_field_assoc, 3, {:atom, 3, :first}, {:integer, 3, 1}},
                    {:map_field_assoc, 3, {:atom, 3, :last}, {:integer, 3, 12}}
                  ]}
               ]}
            ]} = range
  end

  @tag :ex_gt_1_11
  test "step range" do
    {tokens, ast} = load("Elixir.RangeStep.beam", "1.12/range_step.ex")

    [to_list, match_range, rev_range_step, range_step, range | _] =
      AstSpecifier.run_mappers(ast, tokens) |> Enum.reverse()

    assert {:function, 18, :to_list, 0,
            [
              {:clause, 18, [], [],
               [
                 {:call, 19, {:remote, 19, {:atom, 19, Enum}, {:atom, 19, :to_list}},
                  [
                    {:map, 19,
                     [
                       {:map_field_assoc, 19, {:atom, 19, :__struct__}, {:atom, 19, Range}},
                       {:map_field_assoc, 19, {:atom, 19, :first}, {:integer, 19, 1}},
                       {:map_field_assoc, 19, {:atom, 19, :last}, {:integer, 19, 100}},
                       {:map_field_assoc, 19, {:atom, 19, :step}, {:integer, 19, 5}}
                     ]}
                  ]}
               ]}
            ]} = to_list

    assert {:function, 14, :match_range, 0,
            [
              {:clause, 14, [], [],
               [
                 {:match, 15,
                  {:map, 15,
                   [
                     {:map_field_exact, 15, {:atom, 15, :__struct__}, {:atom, 15, Range}},
                     {:map_field_exact, 15, {:atom, 15, :first}, {:var, 15, :_first@1}},
                     {:map_field_exact, 15, {:atom, 15, :last}, {:var, 15, :_last@1}},
                     {:map_field_exact, 15, {:atom, 15, :step}, {:var, 15, :_step@1}}
                   ]}, {:call, 15, {:atom, 15, :range_step}, []}}
               ]}
            ]} = match_range

    assert {:function, 10, :rev_range_step, 0,
            [
              {:clause, 10, [], [],
               [
                 {:map, 11,
                  [
                    {:map_field_assoc, 11, {:atom, 11, :__struct__}, {:atom, 11, Range}},
                    {:map_field_assoc, 11, {:atom, 11, :first}, {:integer, 11, 12}},
                    {:map_field_assoc, 11, {:atom, 11, :last}, {:integer, 11, 1}},
                    {:map_field_assoc, 11, {:atom, 11, :step}, {:integer, 11, -2}}
                  ]}
               ]}
            ]} = rev_range_step

    assert {:function, 6, :range_step, 0,
            [
              {:clause, 6, [], [],
               [
                 {:map, 7,
                  [
                    {:map_field_assoc, 7, {:atom, 7, :__struct__}, {:atom, 7, Range}},
                    {:map_field_assoc, 7, {:atom, 7, :first}, {:integer, 7, 1}},
                    {:map_field_assoc, 7, {:atom, 7, :last}, {:integer, 7, 12}},
                    {:map_field_assoc, 7, {:atom, 7, :step}, {:integer, 7, 2}}
                  ]}
               ]}
            ]} = range_step

    assert {:function, 2, :range, 0,
            [
              {:clause, 2, [], [],
               [
                 {:map, 3,
                  [
                    {:map_field_assoc, 3, {:atom, 3, :__struct__}, {:atom, 3, Range}},
                    {:map_field_assoc, 3, {:atom, 3, :first}, {:integer, 3, 1}},
                    {:map_field_assoc, 3, {:atom, 3, :last}, {:integer, 3, 12}},
                    {:map_field_assoc, 3, {:atom, 3, :step}, {:integer, 3, 1}}
                  ]}
               ]}
            ]} = range
  end

  test "list comprehension" do
    {tokens, ast} = load("Elixir.ListComprehension.beam", "list_comprehension.ex")

    [block | _] = AstSpecifier.run_mappers(ast, tokens) |> Enum.reverse()

    range =
      if System.version() >= "1.12" do
        {:map, 11,
         [
           {:map_field_assoc, 11, {:atom, 11, :__struct__}, {:atom, 11, Range}},
           {:map_field_assoc, 11, {:atom, 11, :first}, {:integer, 11, 0}},
           {:map_field_assoc, 11, {:atom, 11, :last}, {:integer, 11, 5}},
           {:map_field_assoc, 11, {:atom, 11, :step}, {:integer, 11, 1}}
         ]}
      else
        {:map, 11,
         [
           {:map_field_assoc, 11, {:atom, 11, :__struct__}, {:atom, 11, Range}},
           {:map_field_assoc, 11, {:atom, 11, :first}, {:integer, 11, 0}},
           {:map_field_assoc, 11, {:atom, 11, :last}, {:integer, 11, 5}}
         ]}
      end

    assert {:function, 10, :lc_complex, 0,
            [
              {:clause, 10, [], [],
               [
                 {:call, 11, {:remote, 11, {:atom, 11, :lists}, {:atom, 11, :reverse}},
                  [
                    {:call, 11, {:remote, 11, {:atom, 11, Enum}, {:atom, 11, :reduce}},
                     [
                       ^range,
                       {nil, 11},
                       {:fun, 11,
                        {:clauses,
                         [
                           {:clause, 11, [{:var, 11, :_n@1}, {:var, 11, :_@1}], [],
                            [
                              {:case, [generated: true, location: 11],
                               {:op, 11, :==,
                                {:op, 11, :rem, {:var, 11, :_n@1}, {:integer, 11, 3}},
                                {:integer, 11, 0}},
                               [
                                 {:clause, [generated: true, location: 11],
                                  [{:atom, [generated: true, location: 11], true}], [],
                                  [
                                    {:cons, 11,
                                     {:op, 11, :*, {:var, 11, :_n@1}, {:var, 11, :_n@1}},
                                     {:var, 11, :_@1}}
                                  ]},
                                 {:clause, [generated: true, location: 11],
                                  [{:atom, [generated: true, location: 11], false}], [],
                                  [{:var, 11, :_@1}]}
                               ]}
                            ]}
                         ]}}
                     ]}
                  ]}
               ]}
            ]} = block
  end

  test "list" do
    {tokens, ast} = load("Elixir.ListEx.beam", "list.ex")

    [ht2, ht, list, _wrap | _] = AstSpecifier.run_mappers(ast, tokens) |> Enum.reverse()

    assert {:function, 5, :list, 0,
            [
              {:clause, 5, [], [],
               [
                 {:cons, 6,
                  {:cons, 6, {:integer, 6, 49}, {:cons, 6, {:integer, 6, 49}, {nil, 6}}},
                  {:cons, 6,
                   {:bin, 6, [{:bin_element, 6, {:string, 6, '12'}, :default, :default}]},
                   {:cons, 6, {:integer, 6, 1},
                    {:cons, 6, {:integer, 6, 2},
                     {:cons, 6, {:integer, 6, 3},
                      {:cons, 6, {:call, 6, {:atom, 6, :wrap}, [{:integer, 6, 4}]}, {nil, 6}}}}}}}
               ]}
            ]} = list

    assert {:function, 9, :ht, 1,
            [
              {:clause, 9, [{:cons, 9, {:var, 9, :_a@1}, {:var, 9, :_}}], [],
               [
                 {:cons, 10, {:var, 10, :_a@1},
                  {:cons, 10, {:integer, 10, 1},
                   {:cons, 10, {:integer, 10, 2}, {:cons, 10, {:integer, 10, 3}, {nil, 10}}}}}
               ]}
            ]} = ht

    assert {:function, 13, :ht2, 1,
            [
              {:clause, 13, [{:cons, 13, {:var, 13, :_a@1}, {:var, 13, :_}}], [],
               [
                 {:cons, 14, {:var, 14, :_a@1},
                  {:call, 14, {:atom, 14, :wrap}, [{:integer, 14, 1}]}}
               ]}
            ]} = ht2
  end

  test "try" do
    {tokens, ast} = load("Elixir.Try.beam", "try.ex")

    [body_after, try_after, try_else, try_rescue | _] =
      AstSpecifier.run_mappers(ast, tokens) |> Enum.reverse()

    assert {:function, 2, :try_rescue, 0,
            [
              {:clause, 2, [], [],
               [
                 {:try, 3,
                  [
                    {:case, 4, {:atom, 4, true},
                     [
                       {:clause, [generated: true, location: 4],
                        [{:atom, [generated: true, location: 4], false}], [],
                        [
                          {:call, 7, {:remote, 7, {:atom, 7, :erlang}, {:atom, 7, :error}},
                           [
                             {:call, 7,
                              {:remote, 7, {:atom, 7, RuntimeError}, {:atom, 7, :exception}},
                              [
                                {:bin, 7,
                                 [
                                   {:bin_element, 7, {:string, 7, 'oops'}, :default, :default}
                                 ]}
                              ]}
                             | _
                           ]}
                        ]},
                       {:clause, [generated: true, location: 4],
                        [{:atom, [generated: true, location: 4], true}], [],
                        [
                          {:call, 5, {:remote, 5, {:atom, 5, :erlang}, {:atom, 5, :throw}},
                           [
                             {:bin, 5,
                              [{:bin_element, 5, {:string, 5, 'good'}, :default, :default}]}
                           ]}
                        ]}
                     ]}
                  ], [],
                  [
                    {:clause, 10,
                     [
                       {:tuple, 10,
                        [
                          {:atom, 10, :error},
                          {:var, 10, :_@1},
                          {:var, 10, :___STACKTRACE__@1}
                        ]}
                     ],
                     [
                       [
                         {:op, 10, :andalso,
                          {:op, 10, :==,
                           {:call, 10, {:remote, 10, {:atom, 10, :erlang}, {:atom, 10, :map_get}},
                            [{:atom, 10, :__struct__}, {:var, 10, :_@1}]},
                           {:atom, 10, RuntimeError}},
                          {:call, 10, {:remote, 10, {:atom, 10, :erlang}, {:atom, 10, :map_get}},
                           [{:atom, 10, :__exception__}, {:var, 10, :_@1}]}}
                       ]
                     ],
                     [
                       {:match, 10, {:var, 10, :_e@1}, {:var, 10, :_@1}},
                       {:integer, 11, 11},
                       {:var, 12, :_e@1}
                     ]},
                    {:clause, 14,
                     [
                       {:tuple, 14,
                        [
                          {:atom, 14, :throw},
                          {:var, 14, :_val@1},
                          {:var, 14, :___STACKTRACE__@1}
                        ]}
                     ], [], [{:integer, 15, 12}, {:var, 16, :_val@1}]}
                  ], []}
               ]}
            ]} = try_rescue

    assert {:function, 20, :try_else, 0,
            [
              {:clause, 20, [], [],
               [
                 {:match, 21, {:var, 21, :_x@1}, {:integer, 21, 2}},
                 {:try, 23, [{:op, 24, :/, {:integer, 24, 1}, {:var, 24, :_x@1}}],
                  [
                    {:clause, 30, [{:var, 30, :_y@1}],
                     [
                       [
                         {:op, 30, :andalso, {:op, 30, :<, {:var, 30, :_y@1}, {:integer, 30, 1}},
                          {:op, 30, :>, {:var, 30, :_y@1}, {:op, 30, :-, {:integer, 30, 1}}}}
                       ]
                     ], [{:integer, 31, 2}, {:atom, 32, :small}]},
                    {:clause, 34, [{:var, 34, :_}], [], [{:integer, 35, 3}, {:atom, 36, :large}]}
                  ],
                  [
                    {:clause, 26,
                     [
                       {:tuple, 26,
                        [
                          {:atom, 26, :error},
                          {:var, 26, :_@1},
                          {:var, 26, :___STACKTRACE__@1}
                        ]}
                     ],
                     [
                       [{:op, 26, :==, {:var, 26, :_@1}, {:atom, 26, :badarith}}],
                       [
                         {:op, 26, :andalso,
                          {:op, 26, :==,
                           {:call, 26, {:remote, 26, {:atom, 26, :erlang}, {:atom, 26, :map_get}},
                            [{:atom, 26, :__struct__}, {:var, 26, :_@1}]},
                           {:atom, 26, ArithmeticError}},
                          {:call, 26, {:remote, 26, {:atom, 26, :erlang}, {:atom, 26, :map_get}},
                           [{:atom, 26, :__exception__}, {:var, 26, :_@1}]}}
                       ]
                     ], [{:integer, 27, 1}, {:atom, 28, :infinity}]}
                  ], []}
               ]}
            ]} = try_else

    assert {:function, 40, :try_after, 0,
            [
              {:clause, 40, [], [],
               [
                 {:match, 41, {:tuple, 41, [{:atom, 41, :ok}, {:var, 41, :_file@1}]},
                  {:call, 41, {:remote, 41, {:atom, 41, File}, {:atom, 41, :open}},
                   [
                     {:bin, 41,
                      [{:bin_element, 41, {:string, 41, 'sample'}, :default, :default}]},
                     {:cons, 41, {:atom, 41, :utf8}, {:cons, 41, {:atom, 41, :write}, {nil, 41}}}
                   ]}},
                 {:try, 43,
                  [
                    {:call, 44, {:remote, 44, {:atom, 44, IO}, {:atom, 44, :write}},
                     [
                       {:var, 44, :_file@1},
                       {:bin, 44,
                        [
                          {:bin_element, 44, {:string, 44, [111, 108, 195, 161]}, :default,
                           :default}
                        ]}
                     ]},
                    {:call, 45, {:remote, 45, {:atom, 45, :erlang}, {:atom, 45, :error}},
                     [
                       {:call, 45,
                        {:remote, 45, {:atom, 45, RuntimeError}, {:atom, 45, :exception}},
                        [
                          {:bin, 45,
                           [
                             {:bin_element, 45, {:string, 45, 'oops, something went wrong'},
                              :default, :default}
                           ]}
                        ]}
                       | _
                     ]}
                  ], [], [],
                  [
                    {:call, 47, {:remote, 47, {:atom, 47, File}, {:atom, 47, :close}},
                     [{:var, 47, :_file@1}]}
                  ]}
               ]}
            ]} = try_after

    assert {:function, 51, :body_after, 0,
            [
              {:clause, 51, [], [],
               [
                 {:try, 51,
                  [
                    {:call, 52, {:remote, 52, {:atom, 52, :erlang}, {:atom, 52, :error}},
                     [
                       {:call, 52, {:remote, 52, {:atom, 52, Kernel.Utils}, {:atom, 52, :raise}},
                        [
                          {:cons, 52, {:integer, 52, 49},
                           {:cons, 52, {:integer, 52, 50}, {nil, 52}}}
                        ]}
                       | _
                     ]},
                    {:integer, 53, 1}
                  ], [], [], [{:op, 55, :-, {:integer, 55, 1}}]}
               ]}
            ]} = body_after
  end

  test "map" do
    {tokens, ast} = load("Elixir.MapEx.beam", "map.ex")

    [pattern_matching_str, pattern_matching, test_map_str, test_map, empty_map | _] =
      AstSpecifier.run_mappers(ast, tokens) |> Enum.reverse()

    assert {:function, 2, :empty_map, 0, [{:clause, 2, [], [], [{:map, 3, []}]}]} = empty_map

    assert {:function, 6, :test_map, 0,
            [
              {:clause, 6, [], [],
               [
                 {:map, 7,
                  [
                    {:map_field_assoc, 7, {:atom, {:atom, [location: {7, 7}, end_location: {7, 8}], :a}, :a}, {:integer, {:atom, [location: {7, 10}, end_location: {7, 12}], :a}, 12}},
                    {:map_field_assoc, 7, {:atom, [location: {7, 14}, end_location: {7, 15}], :b}, {:call, [location: {7, 17}, end_location: {7, 27}], {:atom, 7, :empty_map}, []}}
                  ]}
               ]}
            ]} = test_map

    assert {:function, 10, :test_map_str, 0,
            [
              {:clause, 10, [], [],
               [
                 {:map, 11,
                  [
                    {:map_field_assoc, 11,
                     {:bin, 11, [{:bin_element, 11, {:string, 11, 'a'}, :default, :default}]},
                     {:integer, 11, 12}},
                    {:map_field_assoc, 11,
                     {:bin, 11, [{:bin_element, 11, {:string, 11, 'b'}, :default, :default}]},
                     {:integer, 11, 0}}
                  ]}
               ]}
            ]} = test_map_str

    assert {:function, 14, :pattern_matching, 0,
            [
              {:clause, 14, [], [],
               [
                 {:match, 15,
                  {:map, 15, [{:map_field_exact, 15, {:atom, 15, :a}, {:var, 15, :_a@1}}]},
                  {:call, 15, {:atom, 15, :test_map}, []}},
                 {:match, 16,
                  {:map, 16, [{:map_field_exact, 16, {:atom, 16, :b}, {:var, 16, :_a@1}}]},
                  {:call, 16, {:atom, 16, :test_map}, []}}
               ]}
            ]} = pattern_matching

    assert {:function, 19, :pattern_matching_str, 0,
            [
              {:clause, 19, [], [],
               [
                 {:match, 20,
                  {:map, 20,
                   [
                     {:map_field_exact, 20,
                      {:bin, 20, [{:bin_element, 20, {:string, 20, 'a'}, :default, :default}]},
                      {:var, 20, :_a@1}}
                   ]}, {:call, 20, {:atom, 20, :test_map}, []}}
               ]}
            ]} = pattern_matching_str
  end

  test "struct" do
    {tokens, ast} = load("Elixir.StructEx.beam", "struct/struct.ex")

    [get2, get, update, empty, struct | _] =
      AstSpecifier.run_mappers(ast, tokens) |> Enum.reverse()

    anno_line_17 = if(System.version() >= "1.12", do: [generated: true, location: 17], else: 17)

    assert {:function, 8, :update, 0,
            [
              {:clause, 8, [], [],
               [
                 {:map, 9, {:call, 9, {:atom, 9, :empty}, []},
                  [{:map_field_exact, 9, {:atom, 9, :x}, {:integer, 9, 13}}]}
               ]}
            ]} = update

    assert {:function, 16, :get2, 0,
            [
              {:clause, 16, [], [],
               [
                 {:match, 17, {:var, 17, :_x@1},
                  {:case, [generated: true, location: 17], {:call, 17, {:atom, 17, :update}, []},
                   [
                     {:clause, [generated: true, location: 17],
                      [
                        {:map, 17,
                         [
                           {:map_field_exact, 17, {:atom, [generated: true, location: 17], :x},
                            {:var, ^anno_line_17, :_@1}}
                         ]}
                      ], [], [{:var, ^anno_line_17, :_@1}]},
                     {:clause, [generated: true, location: 17], [{:var, ^anno_line_17, :_@1}],
                      [
                        [
                          {:call, [generated: true, location: 17],
                           {:remote, [generated: true, location: 17],
                            {:atom, [generated: true, location: 17], :erlang},
                            {:atom, [generated: true, location: 17], :is_map}},
                           [{:var, ^anno_line_17, :_@1}]}
                        ]
                      ],
                      [
                        {:call, 17, {:remote, 17, {:atom, 17, :erlang}, {:atom, 17, :error}},
                         [
                           {:tuple, 17,
                            [
                              {:atom, 17, :badkey},
                              {:atom, 17, :x},
                              {:var, ^anno_line_17, :_@1}
                            ]}
                         ]}
                      ]},
                     {:clause, [generated: true, location: 17], [{:var, ^anno_line_17, :_@1}], [],
                      [
                        {:call, [generated: true, location: 17],
                         {:remote, [generated: true, location: 17], {:var, ^anno_line_17, :_@1},
                          {:atom, 17, :x}}, []}
                      ]}
                   ]}}
               ]}
            ]} = get2

    assert {:function, 12, :get, 0,
            [
              {:clause, 12, [], [],
               [
                 {:match, 13,
                  {:map, 13,
                   [
                     {:map_field_exact, 13, {:atom, 13, :__struct__}, {:atom, 13, StructEx}},
                     {:map_field_exact, 13, {:atom, 13, :x}, {:var, 13, :_x@1}}
                   ]}, {:call, 13, {:atom, 13, :update}, []}}
               ]}
            ]} = get

    assert {:function, 4, :empty, 0,
            [
              {:clause, 4, [], [],
               [
                 {:map, 5,
                  [
                    {:map_field_assoc, 5, {:atom, 5, :__struct__}, {:atom, 5, StructEx}},
                    {:map_field_assoc, 5, {:atom, 5, :x}, {:integer, 5, 0}},
                    {:map_field_assoc, 5, {:atom, 5, :y}, {:integer, 5, 0}}
                  ]}
               ]}
            ]} = empty

    assert {:function, 2, :__struct__, 1,
            [
              {:clause, 2, [{:var, 2, :_@1}], [],
               [
                 {:call, 2, {:remote, 2, {:atom, 2, Enum}, {:atom, 2, :reduce}},
                  [
                    {:var, 2, :_@1},
                    {:map, 2,
                     [
                       {:map_field_assoc, 2, {:atom, 2, :__struct__}, {:atom, 2, StructEx}},
                       {:map_field_assoc, 2, {:atom, 2, :x}, {:integer, 2, 0}},
                       {:map_field_assoc, 2, {:atom, 2, :y}, {:integer, 2, 0}}
                     ]},
                    {:fun, 2,
                     {:clauses,
                      [
                        {:clause, 2,
                         [{:tuple, 2, [{:var, 2, :_@2}, {:var, 2, :_@3}]}, {:var, 2, :_@4}], [],
                         [
                           {:call, 2, {:remote, 2, {:atom, 2, :maps}, {:atom, 2, :update}},
                            [{:var, 2, :_@2}, {:var, 2, :_@3}, {:var, 2, :_@4}]}
                         ]}
                      ]}}
                  ]}
               ]}
            ]} = struct
  end

  test "record" do
    {tokens, ast} = load("Elixir.RecordEx.beam", "record/record.ex")

    [update, init, empty, macro3, macro2, macro1 | _] =
      AstSpecifier.run_mappers(ast, tokens) |> Enum.reverse()

    assert {:function, 7, :empty, 0,
            [
              {:clause, 7, [], [],
               [{:tuple, 8, [{:atom, 8, :record_ex}, {:integer, 8, 0}, {:integer, 8, 0}]}]}
            ]} = empty

    assert {:function, 11, :init, 0,
            [
              {:clause, 11, [], [],
               [{:tuple, 12, [{:atom, 12, :record_ex}, {:integer, 12, 1}, {:integer, 12, 0}]}]}
            ]} = init

    elixir_env_arg = if System.version() >= "1.13", do: :to_caller, else: :linify

    assert {:function, 5, :"MACRO-record_ex", 1,
            [
              {:clause, 5, [{:var, 5, :_@CALLER}], [],
               [
                 {:match, 5, {:var, 5, :__CALLER__},
                  {:call, 5, {:remote, 5, {:atom, 5, :elixir_env}, {:atom, 5, ^elixir_env_arg}},
                   [{:var, 5, :_@CALLER}]}},
                 {:call, 5, {:atom, 5, :"MACRO-record_ex"}, [{:var, 5, :__CALLER__}, {nil, 5}]}
               ]}
            ]} = macro1

    assert {:function, 5, :"MACRO-record_ex", 2,
            [
              {:clause, 5, [{:var, 5, :_@CALLER}, {:var, 5, :_@1}], [],
               [
                 {:match, 5, {:var, 5, :__CALLER__},
                  {:call, 5, {:remote, 5, {:atom, 5, :elixir_env}, {:atom, 5, ^elixir_env_arg}},
                   [{:var, 5, :_@CALLER}]}},
                 {:call, 5, {:remote, 5, {:atom, 5, Record}, {:atom, 5, :__access__}},
                  [
                    {:atom, 5, :record_ex},
                    {:cons, 5, {:tuple, 5, [{:atom, 5, :x}, {:integer, 5, 0}]},
                     {:cons, 5, {:tuple, 5, [{:atom, 5, :y}, {:integer, 5, 0}]}, {nil, 5}}},
                    {:var, 5, :_@1},
                    {:var, 5, :__CALLER__}
                  ]}
               ]}
            ]} = macro2

    assert {:function, 5, :"MACRO-record_ex", 3,
            [
              {:clause, 5, [{:var, 5, :_@CALLER}, {:var, 5, :_@1}, {:var, 5, :_@2}], [],
               [
                 {:match, 5, {:var, 5, :__CALLER__},
                  {:call, 5, {:remote, 5, {:atom, 5, :elixir_env}, {:atom, 5, ^elixir_env_arg}},
                   [{:var, 5, :_@CALLER}]}},
                 {:call, 5, {:remote, 5, {:atom, 5, Record}, {:atom, 5, :__access__}},
                  [
                    {:atom, 5, :record_ex},
                    {:cons, 5, {:tuple, 5, [{:atom, 5, :x}, {:integer, 5, 0}]},
                     {:cons, 5, {:tuple, 5, [{:atom, 5, :y}, {:integer, 5, 0}]}, {nil, 5}}},
                    {:var, 5, :_@1},
                    {:var, 5, :_@2},
                    {:var, 5, :__CALLER__}
                  ]}
               ]}
            ]} = macro3

    assert {:function, 16, :update, 1,
            [
              {:clause, 16, [{:var, 16, :_record@1}], [],
               [
                 {:call, 17, {:remote, 17, {:atom, 17, :erlang}, {:atom, 17, :setelement}},
                  [
                    {:integer, 17, 2},
                    {:call, 17, {:remote, 17, {:atom, 17, :erlang}, {:atom, 17, :setelement}},
                     [{:integer, 17, 3}, {:var, 17, :_record@1}, {:integer, 17, 3}]},
                    {:integer, 17, 2}
                  ]}
               ]}
            ]} = update
  end

  test "receive" do
    {tokens, ast} = load("Elixir.Receive.beam", "receive.ex")

    [recv, recv2 | _] = AstSpecifier.run_mappers(ast, tokens) |> Enum.reverse()

    assert {:function, 2, :recv2, 0,
            [
              {:clause, 2, [], [],
               [
                 {:call, 3, {:remote, 3, {:atom, 3, :erlang}, {:atom, 3, :send}},
                  [
                    {:call, 3, {:remote, 3, {:atom, 3, :erlang}, {:atom, 3, :self}}, []},
                    {:tuple, 3,
                     [
                       {:atom, 3, :hello},
                       {:bin, 3, [{:bin_element, 3, {:string, 3, 'All'}, :default, :default}]}
                     ]}
                  ]},
                 {:receive, 5,
                  [
                    {:clause, 6, [{:tuple, 6, [{:atom, 6, :hello}, {:var, 6, :_to@1}]}], [],
                     [
                       {:call, 7, {:remote, 7, {:atom, 7, IO}, {:atom, 7, :puts}},
                        [
                          {:bin, 7,
                           [
                             {:bin_element, 7, {:string, 7, 'Hello, '}, :default, :default},
                             {:bin_element, 7, {:var, 7, :_to@1}, :default, [:binary]}
                           ]}
                        ]}
                     ]},
                    {:clause, 9, [{:atom, 9, :skip}], [], [{:atom, 10, :ok}]}
                  ], {:integer, 12, 1000},
                  [
                    {:call, 13, {:remote, 13, {:atom, 13, IO}, {:atom, 13, :puts}},
                     [
                       {:bin, 13,
                        [{:bin_element, 13, {:string, 13, 'Timeout'}, :default, :default}]}
                     ]}
                  ]}
               ]}
            ]} = recv2

    assert {:function, 17, :recv, 0,
            [
              {:clause, 17, [], [],
               [{:receive, 18, [{:clause, 19, [{:atom, 19, :ok}], [], [{:atom, 19, :ok}]}]}]}
            ]} = recv
  end

  test "typespec when" do
    {tokens, ast} = load("Elixir.TypespecWhen.beam", "/typespec_when.ex")

    [spec | _] =
      AstSpecifier.run_mappers(ast, tokens)
      |> filter_attributes(:spec)
      |> Enum.reverse()

    assert {:attribute, 2, :spec,
            {{:foo, 1},
             [
               {:type, 2, :bounded_fun,
                [
                  {:type, 2, :fun,
                   [
                     {:type, 2, :product, [{:type, 2, :tuple, [{:atom, 2, :a}, {:var, 2, :x}]}]},
                     {:type, 2, :union,
                      [
                        {:type, 2, :tuple, [{:atom, 2, :a}, {:var, 2, :x}]},
                        {:type, 2, :tuple, [{:atom, 2, :b}, {:var, 2, :x}]}
                      ]}
                   ]},
                  [
                    {:type, 2, :constraint,
                     [{:atom, 2, :is_subtype}, [{:var, 2, :x}, {:type, 2, :term, []}]]}
                  ]
                ]}
             ]}} = spec
  end

  test "typespec behavior" do
    {tokens, ast} = load("Elixir.TypespecBeh.beam", "/typespec_beh.ex")

    [callback1, callback2 | _] =
      AstSpecifier.run_mappers(ast, tokens)
      |> filter_attributes(:callback)
      |> Enum.reverse()

    assert {:attribute, 4, :callback,
            {{:"MACRO-non_vital_macro", 2},
             [
               {:type, 4, :fun,
                [
                  {:type, 4, :product,
                   [
                     {:type, 4, :term, []},
                     {:ann_type, 4, [{:var, 4, :arg}, {:type, 4, :any, []}]}
                   ]},
                  {:remote_type, 4, [{:atom, 4, Macro}, {:atom, 4, :t}, []]}
                ]}
             ]}} = callback1

    assert {:attribute, 3, :callback,
            {{:non_vital_fun, 0},
             [
               {:type, 3, :bounded_fun,
                [
                  {:type, 3, :fun, [{:type, 3, :product, []}, {:var, 3, :a}]},
                  [
                    {:type, 3, :constraint,
                     [
                       {:atom, 3, :is_subtype},
                       [
                         {:var, 3, :a},
                         {:type, 3, :tuple, [{:type, 3, :integer, []}, {:type, 3, :atom, []}]}
                       ]
                     ]}
                  ]
                ]}
             ]}} = callback2
  end

  test "typespec" do
    {tokens, ast} = load("Elixir.Typespec.beam", "typespec.ex")

    result =
      AstSpecifier.run_mappers(ast, tokens)
      |> filter_attributes(:spec)
      |> make_spec_map()

    assert {:attribute, 6, :spec,
            {{:spec_remote_type, 0},
             [
               {:type, 6, :fun,
                [
                  {:type, 6, :product, []},
                  {:remote_type, 6, [{:atom, 6, Unknown}, {:atom, 6, :atom}, []]}
                ]}
             ]}} = result.spec_remote_type

    assert {:attribute, 9, :spec,
            {{:spec_user_type, 0},
             [
               {:type, 9, :fun,
                [
                  {:type, 9, :product, []},
                  {:user_type, 9, :mylist,
                   [{:type, 9, :union, [{:atom, 9, :ok}, {:type, 9, :atom, []}]}]}
                ]}
             ]}} = result.spec_user_type

    assert {:attribute, 12, :spec,
            {{:spec_map_and_named_type, 1},
             [
               {:type, 12, :fun,
                [
                  {:type, 12, :product,
                   [
                     {:ann_type, 12,
                      [
                        {:var, 12, :type},
                        {:remote_type, 12, [{:atom, 12, Unknown}, {:atom, 12, :atom}, []]}
                      ]}
                   ]},
                  {:type, 12, :map,
                   [
                     {:type, 13, :map_field_assoc,
                      [{:atom, 13, :value}, {:type, 13, :integer, []}]},
                     {:type, 14, :map_field_exact,
                      [
                        {:atom, 14, :type},
                        {:remote_type, 14, [{:atom, 14, Unknown}, {:atom, 14, :atom}, []]}
                      ]}
                   ]}
                ]}
             ]}} = result.spec_map_and_named_type

    assert {:attribute, 18, :spec,
            {{:spec_atom, 1},
             [
               {:type, 18, :fun,
                [
                  {:type, 18, :product,
                   [
                     {:type, 18, :union,
                      [{:atom, 18, :ok}, {:atom, 18, nil}, {:atom, 18, true}, {:atom, 18, false}]}
                   ]},
                  {:remote_type, 18,
                   [
                     {:atom, 18, Unknown},
                     {:atom, 18, :atom},
                     [
                       {:type, 18, :union,
                        [
                          {:atom, 18, :ok},
                          {:atom, 18, nil},
                          {:atom, 18, true},
                          {:atom, 18, false}
                        ]}
                     ]
                   ]}
                ]}
             ]}} = result.spec_atom

    assert {:attribute, 21, :spec,
            {{:spec_function, 0},
             [
               {:type, 21, :fun,
                [
                  {:type, 21, :product, []},
                  {:type, 21, :fun,
                   [
                     {:type, 21, :product,
                      [
                        {:type, 21, :atom, []},
                        {:type, 21, :map,
                         [
                           {:type, 21, :map_field_exact,
                            [
                              {:atom, 21, :name},
                              {:remote_type, 21, [{:atom, 21, String}, {:atom, 21, :t}, []]}
                            ]}
                         ]}
                      ]},
                     {:type, 21, :map, :any}
                   ]}
                ]}
             ]}} = result.spec_function

    assert {:attribute, 24, :spec,
            {{:spec_struct, 1},
             [
               {:type, 24, :fun,
                [
                  {:type, 24, :product,
                   [
                     {:type, 24, :map,
                      [
                        {:type, 24, :map_field_exact,
                         [{:atom, 24, :__struct__}, {:atom, 24, Typespec}]},
                        {:type, 24, :map_field_exact,
                         [{:atom, 24, :age}, {:type, 24, :term, []}]},
                        {:type, 24, :map_field_exact,
                         [{:atom, 24, :name}, {:type, 24, :term, []}]}
                      ]}
                   ]},
                  {:type, 24, :map,
                   [
                     {:type, 24, :map_field_exact,
                      [{:atom, 24, :__struct__}, {:atom, 24, Typespec}]},
                     {:type, 24, :map_field_exact, [{:atom, 24, :age}, {:type, 24, :term, []}]},
                     {:type, 24, :map_field_exact, [{:atom, 24, :name}, {:type, 24, :term, []}]}
                   ]}
                ]}
             ]}} = result.spec_struct

    assert {:attribute, 27, :spec,
            {{:spec_list, 1},
             [
               {:type, 27, :fun,
                [
                  {:type, 27, :product,
                   [{:type, 27, :nonempty_list, [{:type, 27, :integer, []}]}]},
                  {:type, 27, :nonempty_list, []}
                ]}
             ]}} = result.spec_list

    assert {:attribute, 30, :spec,
            {{:spec_range, 1},
             [
               {:type, 30, :fun,
                [
                  {:type, 30, :product,
                   [{:type, 30, :range, [{:integer, 30, 1}, {:integer, 30, 10}]}]},
                  {:type, 30, :list,
                   [{:type, 30, :range, [{:integer, 30, 1}, {:integer, 30, 10}]}]}
                ]}
             ]}} = result.spec_range

    assert {:attribute, 33, :spec,
            {{:spec_keyword, 1},
             [
               {:type, 33, :fun,
                [
                  {:type, 33, :product,
                   [
                     {:type, 33, :list,
                      [
                        {:type, 33, :union,
                         [
                           {:type, 33, :tuple, [{:atom, 33, :a}, {:type, 33, :integer, []}]},
                           {:type, 33, :tuple, [{:atom, 33, :b}, {:type, 33, :integer, []}]}
                         ]}
                      ]}
                   ]},
                  {:type, 33, :integer, []}
                ]}
             ]}} = result.spec_keyword

    assert {:attribute, 36, :spec,
            {{:spec_tuple, 1},
             [
               {:type, 36, :fun,
                [
                  {:type, 36, :product,
                   [{:type, 36, :tuple, [{:atom, 36, :ok}, {:type, 36, :integer, []}]}]},
                  {:type, 36, :tuple, :any}
                ]}
             ]}} = result.spec_tuple

    assert {:attribute, 39, :spec,
            {{:spec_bitstring, 1},
             [
               {:type, 39, :fun,
                [
                  {:type, 39, :product,
                   [{:type, 39, :binary, [{:integer, 39, 48}, {:integer, 39, 8}]}]},
                  {:type, 39, :binary, [{:integer, 39, 0}, {:integer, 39, 0}]}
                ]}
             ]}} = result.spec_bitstring
  end

  test "clauses without a line" do
    forms = [
      {:function, 8, :__impl__, 1,
       [
         {:clause, [generated: true, location: 0],
          [{:atom, [generated: true, location: 0], :for}], [],
          [{:atom, [generated: true, location: 0], TypedSchemaTest}]}
       ]}
    ]

    assert [_] = AstSpecifier.run_mappers(forms, [])
  end

  test "nested modules" do
    {tokensA, astA} = load("Elixir.NestedModules.ModuleA.beam", "nested_modules.ex")
    {tokensB, astB} = load("Elixir.NestedModules.ModuleB.beam", "nested_modules.ex")
    {tokens, ast} = load("Elixir.NestedModules.beam", "nested_modules.ex")

    assert {:function, 3, :name, 0, [{:clause, 3, [], [], [{:atom, [location: {4, 7}, end_location: {4, 15}], :module_a}]}]} =
             List.last(AstSpecifier.run_mappers(astA, tokensA))

    assert {:function, 9, :name, 0, [{:clause, 9, [], [], [{:atom, [location: {10, 7}, end_location: {10, 15}], :module_b}]}]} =
             List.last(AstSpecifier.run_mappers(astB, tokensB))

    assert {:function, 14, :name, 0, [{:clause, 14, [], [], [{:atom, [location: {15, 5}, end_location: {15, 11}], :module}]}]} =
             List.last(AstSpecifier.run_mappers(ast, tokens))
  end

  # Helpers

  def filter_attributes(ast, type) do
    Enum.filter(ast, &match?({:attribute, _, ^type, _}, &1))
  end

  def make_spec_map(specs) do
    specs
    |> Enum.map(fn {:attribute, _, _, {{name, _arity}, _}} = attr -> {name, attr} end)
    |> Enum.into(%{})
  end
end
