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
                   {:cons, 2, {:integer, 0, 97},
                    {:cons, 0, {:integer, 0, 98}, {:cons, 0, {:integer, 0, 99}, {nil, 0}}}}
                 ]}
              ]} = inline

      assert {:function, 4, :charlist_block, 0,
              [
                {:clause, 4, [], [],
                 [
                   {:cons, 5, {:integer, 0, 97},
                    {:cons, 0, {:integer, 0, 98}, {:cons, 0, {:integer, 0, 99}, {nil, 0}}}}
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
    test "binary" do
      {_tokens, _ast} = load("/basic/Elixir.Basic.Binary.beam", "/basic/binary.ex")

      assert false
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
                   {:case, 13, {:op, 13, :<, {:integer, 0, 1}, {:integer, 0, 5}},
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
                   {:case, 10, {:op, 10, :<, {:integer, 0, 1}, {:integer, 0, 5}},
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
                   {:case, 4, {:op, 4, :<, {:integer, 0, 1}, {:integer, 0, 5}},
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
                   {:case, 4, {:op, 5, :==, {:var, 5, :_a@1}, {:atom, 0, :ok}},
                    [
                      {:clause, 5, [{:atom, 7, true}], [], [{:atom, 5, :ok}]},
                      {:clause, 6, [{:atom, 6, false}], [],
                       [
                         {:case, 6, {:op, 6, :>, {:var, 6, :_a@1}, {:integer, 0, 5}},
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
                                      [{:atom, 0, :cond_clause}]}
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
                   {:case, 13, {:op, 14, :==, {:var, 14, :_a@1}, {:atom, 0, :ok}},
                    [
                      {:clause, 14, [{:atom, 16, true}], [], [{:atom, 14, :ok}]},
                      {:clause, 15, [{:atom, 15, false}], [],
                       [
                         {:case, 15, {:op, 15, :>, {:var, 15, :_a@1}, {:integer, 0, 5}},
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
                                      [{:atom, 0, :cond_clause}]}
                                   ]}
                                ]}
                             ]}
                          ]}
                       ]}
                    ]}
                 ]}
              ]} = block
    end

    test "with statement" do
      {tokens, ast} = load("/Elixir.With.beam", "/with_stmt.ex")

      [block | _] = SpecifyErlAst.add_missing_loc_literals(tokens, ast) |> Enum.reverse()

      assert {:function, 6, :test_with, 0,
              [
                {:clause, 6, [], [],
                 [
                   {:case, [generated: true, location: 7], {:call, 7, {:atom, 7, :ok_res}, []},
                    [
                      {:clause, 7, [{:tuple, 7, [{:atom, 7, :ok}, {:var, 7, :_a@1}]}], [],
                       [{:integer, 8, 12}]},
                      {:clause, 7, [{:var, 10, :_}], [],
                       [{:cons, 11, {:integer, 0, 49}, {:cons, 0, {:integer, 0, 50}, {nil, 0}}}]}
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
