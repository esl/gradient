defmodule GradualizerEx.SpecifyErlAstTest do
  use ExUnit.Case
  doctest GradualizerEx.SpecifyErlAst

  alias GradualizerEx.SpecifyErlAst

  import GradualizerEx.Utils

  @examples_path "test/examples"

  setup_all state do
    {:ok, state}
  end

  describe "get_conditional/1" do
    test "case" do
      {tokens, _ast} = load("/conditional/Elixir.Conditional.Case.beam", "/conditional/case.ex")
      tokens = drop_tokens_to_line(tokens, 2)
      assert {:case, _} = SpecifyErlAst.get_conditional(tokens)

      tokens = drop_tokens_to_line(tokens, 9)
      assert {:case, _} = SpecifyErlAst.get_conditional(tokens)
    end

    test "if" do
      {tokens, _ast} = load("/conditional/Elixir.Conditional.If.beam", "/conditional/if.ex")

      tokens = drop_tokens_to_line(tokens, 2)
      assert {:if, _} = SpecifyErlAst.get_conditional(tokens)

      tokens = drop_tokens_to_line(tokens, 12)
      assert {:if, _} = SpecifyErlAst.get_conditional(tokens)
    end

    test "unless" do
      {tokens, _ast} =
        load("/conditional/Elixir.Conditional.Unless.beam", "/conditional/unless.ex")

      tokens = drop_tokens_to_line(tokens, 2)
      assert {:unless, _} = SpecifyErlAst.get_conditional(tokens)
    end

    test "cond" do
      {tokens, _ast} = load("/conditional/Elixir.Conditional.Cond.beam", "/conditional/cond.ex")

      tokens = drop_tokens_to_line(tokens, 2)
      assert {:cond, _} = SpecifyErlAst.get_conditional(tokens)

      tokens = drop_tokens_to_line(tokens, 10)
      assert {:cond, _} = SpecifyErlAst.get_conditional(tokens)
    end
  end

  describe "add_missing_loc_literals/2" do
    test "messy test on simple_app" do
      {tokens, ast} = example_data()
      new_ast = SpecifyErlAst.add_missing_loc_literals(tokens, ast)

      assert is_list(new_ast)
    end

    test "integer" do
      {tokens, ast} = load("/basic/Elixir.Basic.Int.beam", "/basic/int.ex")

      [block, inline | _] = SpecifyErlAst.add_missing_loc_literals(tokens, ast) |> Enum.reverse()

      assert {:function, 2, :int, 0, [{:clause, 2, [], [], [{:integer, 2, 1}]}]} = inline

      assert {:function, 4, :int_block, 0, [{:clause, 4, [], [], [{:integer, 5, 2}]}]} = block
    end

    test "float" do
      {tokens, ast} = load("/basic/Elixir.Basic.Float.beam", "/basic/float.ex")

      [block, inline | _] = SpecifyErlAst.add_missing_loc_literals(tokens, ast) |> Enum.reverse()
      assert {:function, 2, :float, 0, [{:clause, 2, [], [], [{:float, 2, 0.12}]}]} = inline

      assert {:function, 4, :float_block, 0, [{:clause, 4, [], [], [{:float, 5, 0.12}]}]} = block
    end

    test "atom" do
      {tokens, ast} = load("/basic/Elixir.Basic.Atom.beam", "/basic/atom.ex")

      [block, inline | _] = SpecifyErlAst.add_missing_loc_literals(tokens, ast) |> Enum.reverse()

      assert {:function, 2, :atom, 0, [{:clause, 2, [], [], [{:atom, 2, :ok}]}]} = inline

      assert {:function, 4, :atom_block, 0, [{:clause, 4, [], [], [{:atom, 5, :ok}]}]} = block
    end

    test "char" do
      {tokens, ast} = load("/basic/Elixir.Basic.Char.beam", "/basic/char.ex")

      [block, inline | _] = SpecifyErlAst.add_missing_loc_literals(tokens, ast) |> Enum.reverse()

      assert {:function, 2, :char, 0, [{:clause, 2, [], [], [{:integer, 2, 99}]}]} = inline

      assert {:function, 4, :char_block, 0, [{:clause, 4, [], [], [{:integer, 5, 99}]}]} = block
    end

    test "charlist" do
      {tokens, ast} = load("/basic/Elixir.Basic.Charlist.beam", "/basic/charlist.ex")

      [block, inline | _] = SpecifyErlAst.add_missing_loc_literals(tokens, ast) |> Enum.reverse()

      # TODO propagate location to each charlist element
      assert {:function, 2, :charlist, 0,
              [
                {:clause, 2, [], [],
                 [
                   {:cons, 2, {:integer, 2, 97},
                    {:cons, 2, {:integer, 2, 98}, {:cons, 2, {:integer, 2, 99}, {nil, 0}}}}
                 ]}
              ]} = inline

      assert {:function, 4, :charlist_block, 0,
              [
                {:clause, 4, [], [],
                 [
                   {:cons, 5, {:integer, 5, 97},
                    {:cons, 5, {:integer, 5, 98}, {:cons, 5, {:integer, 5, 99}, {nil, 0}}}}
                 ]}
              ]} = block
    end

    test "string" do
      {tokens, ast} = load("/basic/Elixir.Basic.String.beam", "/basic/string.ex")

      [block, inline | _] = SpecifyErlAst.add_missing_loc_literals(tokens, ast) |> Enum.reverse()

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

    @tag :skip
    test "tuple" do
      {tokens, ast} = load("/Elixir.Tuple.beam", "/tuple.ex")

      IO.inspect(tokens, pretty: true, limit: :infinity)

      [_complex2, _complex, _bin_block, _bin | _] =
        SpecifyErlAst.add_missing_loc_literals(tokens, ast) |> Enum.reverse() |> IO.inspect()

      # FIXME
      assert false
    end

    test "binary" do
      {tokens, ast} = load("/basic/Elixir.Basic.Binary.beam", "/basic/binary.ex")

      [complex2, complex, bin_block, bin | _] =
        SpecifyErlAst.add_missing_loc_literals(tokens, ast)
        |> Enum.reverse()

      assert {:function, 13, :complex2, 0,
              [
                {:clause, 13, [], [],
                 [
                   {:bin, 14,
                    [
                      {:bin_element, 14, {:string, 14, 'abc '}, :default, :default},
                      {:bin_element, 14,
                       {:call, 14, {:remote, 14, {:atom, 0, Kernel}, {:atom, 14, :inspect}},
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
      {tokens, ast} = load("/conditional/Elixir.Conditional.Case.beam", "/conditional/case.ex")

      [block, inline | _] = SpecifyErlAst.add_missing_loc_literals(tokens, ast) |> Enum.reverse()

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
      {tokens, ast} = load("/conditional/Elixir.Conditional.If.beam", "/conditional/if.ex")

      [inline, block, if_ | _] =
        SpecifyErlAst.add_missing_loc_literals(tokens, ast) |> Enum.reverse()

      assert {:function, 12, :if_block, 0,
              [
                {:clause, 12, [], [],
                 [
                   {:case, 13, {:op, 13, :<, {:integer, 13, 1}, {:integer, 13, 5}},
                    [
                      {:clause, 13, [{:atom, 0, false}], [], [{:atom, 16, :error}]},
                      {:clause, 13, [{:atom, 0, true}], [], [{:atom, 14, :ok}]}
                    ]}
                 ]}
              ]} = block

      assert {:function, 10, :if_inline, 0,
              [
                {:clause, 10, [], [],
                 [
                   {:case, 10, {:op, 10, :<, {:integer, 10, 1}, {:integer, 10, 5}},
                    [
                      {:clause, 10, [{:atom, 0, false}], [], [{:atom, 10, :error}]},
                      {:clause, 10, [{:atom, 0, true}], [], [{:atom, 10, :ok}]}
                    ]}
                 ]}
              ]} = inline

      assert {:function, 2, :if_, 0,
              [
                {:clause, 2, [], [],
                 [
                   {:case, 4, {:op, 4, :<, {:integer, 4, 1}, {:integer, 4, 5}},
                    [
                      {:clause, 4, [{:atom, 0, false}], [], [{:atom, 7, :error}]},
                      {:clause, 4, [{:atom, 0, true}], [], [{:atom, 5, :ok}]}
                    ]}
                 ]}
              ]} = if_
    end

    test "unless conditional" do
      {tokens, ast} =
        load("/conditional/Elixir.Conditional.Unless.beam", "/conditional/unless.ex")

      [block | _] = SpecifyErlAst.add_missing_loc_literals(tokens, ast) |> Enum.reverse()

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
                       {:clause, 3, [{:atom, 0, false}], [], [{:atom, 4, :ok}]},
                       {:clause, 3, [{:atom, 0, true}], [], [{:atom, 6, :error}]}
                     ]}
                  ]}
               ]
             } == block
    end

    test "cond conditional" do
      {tokens, ast} = load("/conditional/Elixir.Conditional.Cond.beam", "/conditional/cond.ex")

      [block, inline | _] = SpecifyErlAst.add_missing_loc_literals(tokens, ast) |> Enum.reverse()

      assert {:function, 2, :cond_, 1,
              [
                {:clause, 2, [{:var, 2, :_a@1}], [],
                 [
                   {:case, 4, {:op, 5, :==, {:var, 5, :_a@1}, {:atom, 5, :ok}},
                    [
                      {:clause, 5, [{:atom, 7, true}], [], [{:atom, 5, :ok}]},
                      {:clause, 6, [{:atom, 6, false}], [],
                       [
                         {:case, 6, {:op, 6, :>, {:var, 6, :_a@1}, {:integer, 6, 5}},
                          [
                            {:clause, 6, [{:atom, 7, true}], [], [{:atom, 6, :ok}]},
                            {:clause, 7, [{:atom, 7, false}], [],
                             [
                               {:case, 7, {:atom, 7, true},
                                [
                                  {:clause, 7, [{:atom, 7, true}], [], [{:atom, 7, :error}]},
                                  {:clause, 7, [{:atom, 0, false}], [],
                                   [
                                     {:call, 7,
                                      {:remote, 7, {:atom, 0, :erlang}, {:atom, 7, :error}},
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
                      {:clause, 14, [{:atom, 16, true}], [], [{:atom, 14, :ok}]},
                      {:clause, 15, [{:atom, 15, false}], [],
                       [
                         {:case, 15, {:op, 15, :>, {:var, 15, :_a@1}, {:integer, 15, 5}},
                          [
                            {:clause, 15, [{:atom, 16, true}], [], [{:atom, 15, :ok}]},
                            {:clause, 16, [{:atom, 16, false}], [],
                             [
                               {:case, 16, {:atom, 16, true},
                                [
                                  {:clause, 16, [{:atom, 16, true}], [], [{:atom, 16, :error}]},
                                  {:clause, 16, [{:atom, 0, false}], [],
                                   [
                                     {:call, 16,
                                      {:remote, 16, {:atom, 0, :erlang}, {:atom, 16, :error}},
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
      {tokens, ast} = load("/conditional/Elixir.Conditional.With.beam", "/conditional/with.ex")

      [block | _] = SpecifyErlAst.add_missing_loc_literals(tokens, ast) |> Enum.reverse()

      assert {:function, 6, :test_with, 0,
              [
                {:clause, 6, [], [],
                 [
                   {:case, [generated: true, location: 7], {:call, 7, {:atom, 7, :ok_res}, []},
                    [
                      {:clause, 7, [{:tuple, 7, [{:atom, 7, :ok}, {:var, 7, :__a@1}]}], [],
                       [{:integer, 8, 12}]},
                      {:clause, 7, [{:var, 10, :_}], [],
                       [
                         {:block, 7,
                          [
                            {:call, 11, {:remote, 11, {:atom, 0, IO}, {:atom, 11, :puts}},
                             [
                               {:bin, 11,
                                [{:bin_element, 11, {:string, 11, 'error'}, :default, :default}]}
                             ]},
                            {:cons, 12, {:integer, 12, 49},
                             {:cons, 12, {:integer, 12, 50}, {nil, 0}}}
                          ]}
                       ]}
                    ]}
                 ]}
              ]} == block
    end

    @tag :skip
    test "basic function return" do
      ex_file = "/basic.ex"
      beam_file = "/Elixir.Basic.beam"
      {tokens, ast} = load(beam_file, ex_file)

      specified_ast = SpecifyErlAst.add_missing_loc_literals(tokens, ast)
      IO.inspect(specified_ast)
      assert is_list(specified_ast)
    end
  end

  test "specify_line/2" do
    {tokens, _} = example_data()

    assert {{:integer, 21, 12}, tokens} = SpecifyErlAst.specify_line({:integer, 21, 12}, tokens)

    assert {{:integer, 22, 12}, _tokens} = SpecifyErlAst.specify_line({:integer, 20, 12}, tokens)
  end

  test "cons_to_charlist/1" do
    cons =
      {:cons, 0, {:integer, 0, 49},
       {:cons, 0, {:integer, 0, 48}, {:cons, 0, {:integer, 0, 48}, {nil, 0}}}}

    assert '100' == SpecifyErlAst.cons_to_charlist(cons)
  end

  test "get_list_from_tokens" do
    tokens = example_string_tokens()
    ts = drop_tokens_to_line(tokens, 4)
    assert {:charlist, _} = SpecifyErlAst.get_list_from_tokens(ts)

    ts = drop_tokens_to_line(ts, 6)
    assert {:list, _} = SpecifyErlAst.get_list_from_tokens(ts)
  end

  describe "test that prints result" do
    @tag :skip
    test "specify/1" do
      {_tokens, forms} = example_data()

      SpecifyErlAst.specify(forms)
      |> IO.inspect()
    end

    @tag :skip
    test "display forms" do
      {_, forms} = example_data()
      IO.inspect(forms)
    end
  end

  test "function call" do
    {tokens, ast} = load("/Elixir.Call.beam", "/call.ex")

    [_, block | _] = SpecifyErlAst.add_missing_loc_literals(tokens, ast) |> Enum.reverse()

    assert {:function, 5, :call, 0,
            [
              {:clause, 5, [], [],
               [
                 {:call, 6, {:atom, 6, :get_x},
                  [
                    {:bin, 7, [{:bin_element, 7, {:string, 7, 'ala'}, :default, :default}]},
                    {:cons, 8, {:integer, 8, 97},
                     {:cons, 8, {:integer, 8, 108}, {:cons, 8, {:integer, 8, 97}, {nil, 0}}}},
                    {:integer, 9, 12}
                  ]}
               ]}
            ]} = block
  end

  test "pipe" do
    {tokens, ast} = load("/Elixir.Pipe.beam", "/pipe_op.ex")

    [block | _] = SpecifyErlAst.add_missing_loc_literals(tokens, ast) |> Enum.reverse()

    assert {:function, 2, :pipe, 0,
            [
              {:clause, 2, [], [],
               [
                 {:call, 5, {:remote, 5, {:atom, 0, :erlang}, {:atom, 5, :length}},
                  [
                    {:call, 4, {:remote, 4, {:atom, 0, Enum}, {:atom, 4, :filter}},
                     [
                       {:cons, 4, {:integer, 0, 1},
                        {:cons, 0,
                         {
                           :integer,
                           0,
                           2
                         }, {:cons, 0, {:integer, 0, 3}, {nil, 0}}}},
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
    {tokens, ast} = load("/conditional/Elixir.Conditional.Guard.beam", "/conditional/guards.ex")

    [guarded_fun, guarded_case | _] =
      SpecifyErlAst.add_missing_loc_literals(tokens, ast) |> Enum.reverse()

    assert {:function, 3, :guarded_fun, 1,
            [
              {:clause, 3, [{:var, 3, :_x@1}],
               [
                 [
                   {:call, 3, {:remote, 3, {:atom, 0, :erlang}, {:atom, 3, :is_integer}},
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

  test "list comprehension" do
    {tokens, ast} = load("/Elixir.ListComprehension.beam", "/list_comprehension.ex")

    [block | _] = SpecifyErlAst.add_missing_loc_literals(tokens, ast) |> Enum.reverse()

    assert {:function, 2, :lc, 0,
            [
              {:clause, 2, [], [],
               [
                 {:call, 3, {:remote, 3, {:atom, 3, :lists}, {:atom, 3, :reverse}},
                  [
                    {:call, 3, {:remote, 3, {:atom, 3, Enum}, {:atom, 3, :reduce}},
                     [
                       {:map, 3,
                        [
                          {:map_field_assoc, 3, {:atom, 0, :__struct__}, {:atom, 0, Range}},
                          {:map_field_assoc, 3, {:atom, 0, :first}, {:integer, 0, 0}},
                          {:map_field_assoc, 3, {:atom, 0, :last}, {:integer, 0, 5}},
                          {:map_field_assoc, 3, {:atom, 0, :step}, {:integer, 0, 1}}
                        ]},
                       {nil, 3},
                       {:fun, 3,
                        {:clauses,
                         [
                           {:clause, 3, [{:var, 3, :_n@1}, {:var, 3, :_@1}], [],
                            [
                              {:case, [generated: true, location: 3],
                               {:op, 3, :==, {:op, 3, :rem, {:var, 3, :_n@1}, {:integer, 3, 3}},
                                {:integer, 3, 0}},
                               [
                                 {:clause, 3, [{:atom, [generated: true, location: 3], true}], [],
                                  [
                                    {:cons, 3, {:op, 3, :*, {:var, 3, :_n@1}, {:var, 3, :_n@1}},
                                     {:var, 3, :_@1}}
                                  ]},
                                 {:clause, 3, [{:atom, [generated: true, location: 3], false}],
                                  [], [{:var, 3, :_@1}]}
                               ]}
                            ]}
                         ]}}
                     ]}
                  ]}
               ]}
            ]} = block
  end

  test "list" do
    {tokens, ast} = load("/Elixir.ListEx.beam", "/list.ex")

    [_wrap, list, ht2, ht | _] =
      SpecifyErlAst.add_missing_loc_literals(tokens, ast) |> Enum.reverse()

    assert {:function, 5, :list, 0,
            [
              {:clause, 5, [], [],
               [
                 {:cons, 6,
                  {:cons, 6, {:integer, 6, 49}, {:cons, 6, {:integer, 6, 49}, {nil, 0}}},
                  {:cons, 6,
                   {:bin, 6, [{:bin_element, 6, {:string, 6, '12'}, :default, :default}]},
                   {:cons, 6, {:integer, 6, 1},
                    {:cons, 6, {:integer, 6, 2},
                     {:cons, 6, {:integer, 6, 3},
                      {:cons, 6, {:call, 6, {:atom, 6, :wrap}, [{:integer, 6, 4}]}, {nil, 0}}}}}}}
               ]}
            ]} = list

    assert {:function, 9, :ht, 1,
            [
              {:clause, 9, [{:cons, 9, {:var, 9, :_a@1}, {:var, 9, :_}}], [],
               [
                 {:cons, 10, {:var, 10, :_a@1},
                  {:cons, 10, {:integer, 10, 1},
                   {:cons, 10, {:integer, 10, 2}, {:cons, 10, {:integer, 10, 3}, {nil, 0}}}}}
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
    {tokens, ast} = load("/Elixir.Try.beam", "/try.ex")

    [block | _] = SpecifyErlAst.add_missing_loc_literals(tokens, ast) |> Enum.reverse()

    assert {:function, 2, :try_rescue, 0,
            [
              {:clause, 2, [], [],
               [
                 {:try, 3,
                  [
                    {:case, 4, {:atom, 4, true},
                     [
                       {:clause, 4, [{:atom, 0, false}], [],
                        [
                          {:call, 7, {:remote, 7, {:atom, 0, :erlang}, {:atom, 7, :error}},
                           [
                             {:call, 7,
                              {:remote, 7, {:atom, 0, RuntimeError}, {:atom, 7, :exception}},
                              [
                                {:bin, 7,
                                 [
                                   {:bin_element, 7, {:string, 7, 'oops'}, :default, :default}
                                 ]}
                              ]}
                           ]}
                        ]},
                       {:clause, 4, [{:atom, 0, true}], [],
                        [
                          {:call, 5, {:remote, 5, {:atom, 0, :erlang}, {:atom, 5, :throw}},
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
                           {:call, 10, {:remote, 10, {:atom, 0, :erlang}, {:atom, 10, :map_get}},
                            [{:atom, 10, :__struct__}, {:var, 10, :_@1}]},
                           {:atom, 10, RuntimeError}},
                          {:call, 10, {:remote, 10, {:atom, 0, :erlang}, {:atom, 10, :map_get}},
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
                          {:atom, 0, :throw},
                          {:var, 14, :_val@1},
                          {:var, 14, :___STACKTRACE__@1}
                        ]}
                     ], [], [{:integer, 15, 12}, {:var, 16, :_val@1}]}
                  ], []}
               ]}
            ]} = block
  end

  test "record test" do
    {tokens, ast} = load("/record/Elixir.Test.beam", "/record/test.ex")

    res = SpecifyErlAst.add_missing_loc_literals(tokens, ast) |> Enum.reverse()

    assert is_list(res)
  end

  @spec load(String.t(), String.t()) :: {list(), list()}
  def load(beam_file, ex_file) do
    beam_file = String.to_charlist(@examples_path <> beam_file)
    ex_file = @examples_path <> ex_file

    code =
      File.read!(ex_file)
      |> String.to_charlist()

    {:ok, tokens} =
      code
      |> :elixir.string_to_tokens(1, 1, ex_file, [])

    {:ok, {_, [abstract_code: {:raw_abstract_v1, ast}]}} =
      :beam_lib.chunks(beam_file, [:abstract_code])

    ast = replace_file_path(ast, ex_file)
    {tokens, ast}
  end

  def example_data() do
    beam_path = (@examples_path <> "/Elixir.SimpleApp.beam") |> String.to_charlist()
    file_path = @examples_path <> "/simple_app.ex"

    code =
      File.read!(file_path)
      |> String.to_charlist()

    {:ok, tokens} =
      code
      |> :elixir.string_to_tokens(1, 1, file_path, [])

    {:ok, {SimpleApp, [abstract_code: {:raw_abstract_v1, ast}]}} =
      :beam_lib.chunks(beam_path, [:abstract_code])

    ast = replace_file_path(ast, file_path)
    {tokens, ast}
  end

  def example_string_tokens() do
    file_path = @examples_path <> "/string_test.ex"

    code =
      File.read!(file_path)
      |> String.to_charlist()

    {:ok, tokens} =
      code
      |> :elixir.string_to_tokens(1, 1, file_path, [])

    tokens
  end

  def replace_file_path([_ | forms], path) do
    path = String.to_charlist(path)
    [{:attribute, 1, :file, {path, 1}} | forms]
  end
end
