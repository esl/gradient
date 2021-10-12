<<<<<<< HEAD:lib/gradient/specify_erl_ast.ex
defmodule Gradient.SpecifyErlAst do
=======
defmodule GradualizerEx.AstSpecifier do
>>>>>>> 9a63ccd (Code refactoring, Add docs):lib/gradualizer_ex/ast_specifier.ex
  @moduledoc """
  Module adds missing location information to the Erlang abstract code produced
  from Elixir AST. Moreover it can be used to catch some ast pattern and replace 
  it to forms that cannot be produced from Elixir directly.

  FIXME Optimize tokens searching. Find out why some tokens are dropped 

  NOTE Mapper implements:
  - function [x]
  - fun [x] 
  - fun @spec [x]
  - clause [x] 
  - case [x]
  - block [X] 
  - pipe [x]
  - call [x] (remote [X])
  - match [x]
  - op [x]
  - integer [x]
  - float [x]
  - string [x]
  - charlist [x]
  - tuple [X]
  - var [X]
  - list [X] 
  - keyword [X]
  - binary [X] 
  - map [X] 
  - try [x] 
  - receive [X] 
  - record [X] elixir don't use it record_field, record_index, record_pattern, record
  - named_fun [ ] is named_fun used by elixir? 

  NOTE Elixir expressions to handle or test:
  - list comprehension [X]
  - binary [X]
  - maps [X]
  - struct [X]
  - pipe [ ] TODO decide how to search for line in reversed form order 
  - range [X] 
  - receive [X] 
  - record [X] 
  - guards [X]
  """

<<<<<<< HEAD:lib/gradient/specify_erl_ast.ex
  import Gradient.Utils
=======
  import GradualizerEx.Tokens
>>>>>>> 9a63ccd (Code refactoring, Add docs):lib/gradualizer_ex/ast_specifier.ex

  require Logger

  alias GradualizerEx.Types

  @type token :: Types.token()
  @type tokens :: Types.tokens()
  @type form :: Types.form()
  @type forms :: Types.forms()
  @type options :: Types.options()

  # Api

  @doc """
  Read and tokenize code file. Than run mappers on the given AST (with obtained tokens) 
  to specify missing locations or replace some parts that match pattern.
  """
  @spec specify(nonempty_list(:erl_parse.abstract_form())) :: [:erl_parse.abstract_form()]
  def specify(forms) do
    with {:attribute, line, :file, {path, _}} <- hd(forms),
         path <- to_string(path),
         {:ok, code} <- File.read(path),
<<<<<<< HEAD:lib/gradient/specify_erl_ast.ex
         {:ok, tokens} <- :elixir.string_to_tokens(String.to_charlist(code), line, line, path, []) do
      add_missing_loc_literals(forms, tokens)
=======
         {:ok, tokens} <- :elixir.string_to_tokens(String.to_charlist(code), 1, 1, path, []) do
      run_mappers(forms, tokens)
>>>>>>> 9a63ccd (Code refactoring, Add docs):lib/gradualizer_ex/ast_specifier.ex
    else
      error ->
        IO.puts("Error occured when specifying forms : #{inspect(error)}")
        forms
    end
  end

  @doc """
  Function takes forms and traverse them in order to specify location or modify
  forms matching the pattern. The tokens are required to obtain the missing location 
  as precise as possible.
  """
  @spec run_mappers([:erl_parse.abstract_form()], tokens()) :: [
          :erl_parse.abstract_form()
        ]
  def run_mappers(forms, tokens) do
    opts = [end_line: -1]

    {forms, _} =
      forms
      |> prepare_forms_order()
      |> context_mapper_fold(tokens, opts)

    forms
  end

  # Mappers

  @doc """
  Map over the forms using mapper and attach a context i.e. end line. 
  """
  @spec context_mapper_map(forms(), tokens(), options()) :: forms()
  def context_mapper_map(forms, tokens, opts, mapper \\ &mapper/3)
  def context_mapper_map([], _, _, _), do: []

  def context_mapper_map([form | forms], tokens, opts, mapper) do
    cur_opts = set_form_end_line(opts, form, forms)
    {form, _} = mapper.(form, tokens, cur_opts)
    [form | context_mapper_map(forms, tokens, opts, mapper)]
  end

  @doc """
  Fold over the forms using mapper and attach a context i.e. end line.
  """
  @spec context_mapper_fold(forms(), tokens(), options()) :: {forms(), tokens()}
  def context_mapper_fold(forms, tokens, opts, mapper \\ &mapper/3)
  def context_mapper_fold([], tokens, _, _), do: {[], tokens}

  def context_mapper_fold([form | forms], tokens, opts, mapper) do
    cur_opts = set_form_end_line(opts, form, forms)
    {form, new_tokens} = mapper.(form, tokens, cur_opts)
    {forms, res_tokens} = context_mapper_fold(forms, new_tokens, opts, mapper)
    {[form | forms], res_tokens}
  end

  @doc """
  The main mapper function traverses AST and specifies missing locations
  or replaces parts that match the pattern. 
  """
  @spec mapper(form(), [token()], options()) :: {form(), [token()]}
  def mapper(form, tokens, opts)

  def mapper({:attribute, anno, :spec, {name_arity, specs}}, tokens, opts) do
    new_specs = context_mapper_map(specs, [], opts, &spec_mapper/3)

    {:attribute, anno, :spec, {name_arity, new_specs}}
    |> pass_tokens(tokens)
  end

  def mapper({:function, _line, :__info__, _arity, _children} = form, tokens, _opts) do
    # skip analysis for __info__ functions
    pass_tokens(form, tokens)
  end

  def mapper({:function, anno, name, arity, clauses}, tokens, opts) do
    # anno has line
    {clauses, tokens} = context_mapper_fold(clauses, tokens, opts)

    {:function, anno, name, arity, clauses}
    |> pass_tokens(tokens)
  end

  def mapper({:fun, anno, {:clauses, clauses}}, tokens, opts) do
    # anno has line
    {clauses, tokens} = context_mapper_fold(clauses, tokens, opts)

    {:fun, anno, {:clauses, clauses}}
    |> pass_tokens(tokens)
  end

  def mapper({:case, anno, condition, clauses}, tokens, opts) do
    # anno has line
    # NOTE In Elixir `if`, `case` and `cond` statements are represented 
    # as a `case` in abstract code.
    {:ok, line, anno, opts, _} = get_line(anno, opts)

    opts =
      case get_conditional(tokens, line, opts) do
        {type, _} when type in [:case, :with] ->
          Keyword.put(opts, :case_type, :case)

        {type, _} when type in [:cond, :if, :unless] ->
          Keyword.put(opts, :case_type, :gen)

        :undefined ->
          Keyword.put(opts, :case_type, :gen)
      end

    {new_condition, tokens} = mapper(condition, tokens, opts)

    # NOTE use map because generated clauses can be in wrong order
    clauses = context_mapper_map(clauses, tokens, opts)

    {:case, anno, new_condition, clauses}
    |> pass_tokens(tokens)
  end

  def mapper({:clause, anno, args, guards, children}, tokens, opts) do
    # anno has line
    # FIXME Handle generated clauses. Right now the literals inherit lines 
    # from the parents without checking them with tokens 

    {:ok, line, anno, opts, _} = get_line(anno, opts)
    case_type = Keyword.get(opts, :case_type, :case)

    tokens = drop_tokens_to_line(tokens, line)

    if case_type == :case do
      {guards, tokens} = guards_mapper(guards, tokens, opts)

      {args, tokens} =
        if not :erl_anno.generated(anno) do
          context_mapper_fold(args, tokens, opts)
        else
          {args, tokens}
        end

      {children, tokens} = children |> context_mapper_fold(tokens, opts)

      {:clause, anno, args, guards, children}
      |> pass_tokens(tokens)
    else
      {children, tokens} = children |> context_mapper_fold(tokens, opts)

      {:clause, anno, args, guards, children}
      |> pass_tokens(tokens)
    end
  end

  def mapper({:block, anno, body}, tokens, opts) do
    # TODO check if anno has line
    {:ok, _line, anno, opts, _} = get_line(anno, opts)

    {body, tokens} = context_mapper_fold(body, tokens, opts)

    {:block, anno, body}
    |> pass_tokens(tokens)
  end

  def mapper({:match, anno, left, right}, tokens, opts) do
    {:ok, _, anno, opts, _} = get_line(anno, opts)

    {left, tokens} = mapper(left, tokens, opts)
    {right, tokens} = mapper(right, tokens, opts)

    {:match, anno, left, right}
    |> pass_tokens(tokens)
  end

  def mapper({:map, anno, pairs}, tokens, opts) do
    # anno has correct line
    {:ok, _, anno, opts, _} = get_line(anno, opts)

    {pairs, tokens} = context_mapper_fold(pairs, tokens, opts, &map_element_mapper/3)

    {:map, anno, pairs}
    |> pass_tokens(tokens)
  end

  # update map pattern
  def mapper({:map, anno, map, pairs}, tokens, opts) do
    # anno has correct line
    {:ok, _, anno, opts, _} = get_line(anno, opts)

    {map, tokens} = mapper(map, tokens, opts)
    {pairs, tokens} = context_mapper_fold(pairs, tokens, opts, &map_element_mapper/3)

    {:map, anno, map, pairs}
    |> pass_tokens(tokens)
  end

  def mapper({:cons, anno, value, more} = cons, tokens, opts) do
    # anno could be 0
    {:ok, line, anno, opts, _} = get_line(anno, opts)

    tokens = drop_tokens_to_line(tokens, line)

    case get_list(tokens, opts) do
      {:list, tokens} ->
        cons_mapper(cons, tokens, opts)

      {:keyword, tokens} ->
        cons_mapper(cons, tokens, opts)

      {:charlist, tokens} ->
        {:cons, anno, value, more}
        |> specify_line(tokens, opts)

      :undefined ->
        {form, _} = cons_mapper(cons, [], opts)

        pass_tokens(form, tokens)
    end
  end

  def mapper({:tuple, anno, elements}, tokens, opts) do
    # anno could be 0
    {:ok, line, anno, opts, has_line?} = get_line(anno, opts)

    tokens
    |> drop_tokens_to_line(line)
    |> get_tuple(opts)
    |> case do
      {:tuple, tokens} ->
        {anno, opts} = update_line_from_tokens(tokens, anno, opts, has_line?)

        {elements, tokens} = context_mapper_fold(elements, tokens, opts)

        {:tuple, anno, elements}
        |> pass_tokens(tokens)

      :undefined ->
        elements = context_mapper_map(elements, [], opts)

        {:tuple, anno, elements}
        |> pass_tokens(tokens)
    end
  end

  def mapper({:receive, anno, clauses}, tokens, opts) do
    # anno has correct line
    {:ok, _, anno, opts, _} = get_line(anno, opts)

    {clauses, tokens} = context_mapper_fold(clauses, tokens, opts)

    {:receive, anno, clauses}
    |> pass_tokens(tokens)
  end

  # receive with timeout
  def mapper({:receive, anno, clauses, after_val, after_block}, tokens, opts) do
    # anno has correct line
    {:ok, _, anno, opts, _} = get_line(anno, opts)

    {clauses, tokens} = context_mapper_fold(clauses, tokens, opts)
    {after_val, tokens} = mapper(after_val, tokens, opts)
    {after_block, tokens} = context_mapper_fold(after_block, tokens, opts)

    {:receive, anno, clauses, after_val, after_block}
    |> pass_tokens(tokens)
  end

  def mapper({:try, anno, body, else_block, catchers, after_block}, tokens, opts) do
    # anno has correct line
    {:ok, _, anno, opts, _} = get_line(anno, opts)

    {body, tokens} = context_mapper_fold(body, tokens, opts)

    {catchers, tokens} = context_mapper_fold(catchers, tokens, opts)

    {else_block, tokens} = context_mapper_fold(else_block, tokens, opts)

    {after_block, tokens} = context_mapper_fold(after_block, tokens, opts)

    {:try, anno, body, else_block, catchers, after_block}
    |> pass_tokens(tokens)
  end

  def mapper(
        {:call, anno, {:atom, _, name_atom} = name,
         [expr, {:bin, _, [{:bin_element, _, {:string, _, _} = val, :default, :default}]}]},
        tokens,
        _opts
      )
      when name_atom in [:"::", :":::"] do
    # unwrap string from binary for correct type annotation matching
    {:call, anno, name, [expr, val]}
    |> pass_tokens(tokens)
  end

  def mapper({:call, anno, name, args}, tokens, opts) do
    # anno has correct line
    {:ok, _, anno, opts, _} = get_line(anno, opts)

    name = remote_mapper(name)

    {args, tokens} = context_mapper_fold(args, tokens, opts)

    {:call, anno, name, args}
    |> pass_tokens(tokens)
  end

  def mapper({:op, anno, op, left, right}, tokens, opts) do
    # anno has correct line
    {:ok, _, anno, opts, _} = get_line(anno, opts)

    {left, tokens} = mapper(left, tokens, opts)
    {right, tokens} = mapper(right, tokens, opts)

    {:op, anno, op, left, right}
    |> pass_tokens(tokens)
  end

  def mapper({:op, anno, op, right}, tokens, opts) do
    # anno has correct line
    {:ok, _, anno, opts, _} = get_line(anno, opts)

    {right, tokens} = mapper(right, tokens, opts)

    {:op, anno, op, right}
    |> pass_tokens(tokens)
  end

  def mapper({:bin, anno, elements}, tokens, opts) do
    # anno could be 0
    {:ok, line, anno, opts, _} = get_line(anno, opts)

    # TODO find a way to merge this cases
    case elements do
      [{:bin_element, _, {:string, _, _}, :default, :default}] = e ->
        {:bin, anno, e}
        |> specify_line(tokens, opts)

      _ ->
        {bin_tokens, other_tokens} = cut_tokens_to_bin(tokens, line)
        bin_tokens = flat_tokens(bin_tokens)
        {elements, _} = context_mapper_fold(elements, bin_tokens, opts, &bin_element_mapper/3)

        {:bin, anno, elements}
        |> pass_tokens(other_tokens)
    end
  end

  def mapper({type, 0, value}, tokens, opts)
      when type in [:atom, :char, :float, :integer, :string, :bin] do
    # TODO check what happend for :string
    {:ok, line} = Keyword.fetch(opts, :line)

    {type, line, value}
    |> specify_line(tokens, opts)
  end

  def mapper(skip, tokens, _opts)
      when elem(skip, 0) in [
             :fun,
             :attribute,
             :var,
             nil,
             :atom,
             :char,
             :float,
             :integer,
             :string,
             :bin
           ] do
    # NOTE fun - I skipped here checking &name/arity or &module.name/arity
    # skip forms that don't need analysis and do not display warning
    pass_tokens(skip, tokens)
  end

  def mapper(form, tokens, _opts) do
    Logger.warn("Not found mapper for #{inspect(form)}")
    pass_tokens(form, tokens)
  end

  @doc """
  Adds missing location to the function specification.
  """
  @spec spec_mapper(form(), tokens(), options()) :: {form(), tokens()}
  def spec_mapper({:type, anno, :tuple, :any}, tokens, _opts) do
    {:type, anno, :tuple, :any}
    |> pass_tokens(tokens)
  end

  def spec_mapper({:type, anno, :map, :any}, tokens, _opts) do
    {:type, anno, :map, :any}
    |> pass_tokens(tokens)
  end

  def spec_mapper({:type, anno, :any}, tokens, _opts) do
    {:type, anno, :any}
    |> pass_tokens(tokens)
  end

  def spec_mapper({:type, anno, type_name, args}, tokens, opts) do
    {:ok, _line, anno, opts, _} = get_line(anno, opts)
    new_args = context_mapper_map(args, tokens, opts, &spec_mapper/3)

    {:type, anno, type_name, new_args}
    |> pass_tokens(tokens)
  end

  def spec_mapper({:remote_type, anno, [mod, type, args]}, tokens, opts) do
    {:ok, _line, anno, opts, _} = get_line(anno, opts)
    {new_mod, _} = spec_mapper(mod, tokens, opts)
    {new_type, _} = spec_mapper(type, tokens, opts)
    new_args = context_mapper_map(args, tokens, opts, &spec_mapper/3)

    {:remote_type, anno, [new_mod, new_type, new_args]}
    |> pass_tokens(tokens)
  end

  def spec_mapper({:user_type, anno, name, args}, tokens, opts) do
    new_args = context_mapper_map(args, tokens, opts, &spec_mapper/3)

    {:user_type, anno, name, new_args}
    |> pass_tokens(tokens)
  end

  def spec_mapper({:ann_type, anno, attrs}, tokens, opts) do
    new_attrs = context_mapper_map(attrs, tokens, opts, &spec_mapper/3)

    {:ann_type, anno, new_attrs}
    |> pass_tokens(tokens)
  end

  def spec_mapper(type, tokens, opts) do
    mapper(type, tokens, opts)
  end

  @doc """
  Adds missing location to the module literal
  """
  def remote_mapper({:remote, line, {:atom, 0, mod}, fun}) do
    {:remote, line, {:atom, line, mod}, fun}
  end

  def remote_mapper(name), do: name

  @doc """
  Adds missing location to the literals in the guards
  """
  @spec guards_mapper([form()], [token()], options()) :: {[form()], [token()]}
  def guards_mapper([], tokens, _opts), do: {[], tokens}

  def guards_mapper(guards, tokens, opts) do
    List.foldl(guards, {[], tokens}, fn
      [guard], {gs, tokens} ->
        {g, ts} = mapper(guard, tokens, opts)
        {[[g] | gs], ts}

      gs, {ags, ts} ->
        Logger.error("Unsupported guards format #{inspect(gs)}")
        {gs ++ ags, ts}
    end)
  end

  @doc """
  Run mapper on map value and key.
  """
  @spec map_element_mapper(tuple(), tokens(), options()) :: {tuple(), tokens()}
  def map_element_mapper({field, anno, key, value}, tokens, opts)
      when field in [:map_field_assoc, :map_field_exact] do
    line = :erl_anno.line(anno)
    opts = Keyword.put(opts, :line, line)

    {key, tokens} = mapper(key, tokens, opts)
    {value, tokens} = mapper(value, tokens, opts)

    {field, anno, key, value}
    |> pass_tokens(tokens)
  end

  @doc """
  Run mapper on bin element value.
  """
  @spec bin_element_mapper(tuple(), tokens(), options()) :: {tuple(), tokens()}
  def bin_element_mapper({:bin_element, anno, value, size, tsl}, tokens, opts) do
    {:ok, _line, anno, opts, _} = get_line(anno, opts)

    {value, tokens} = mapper(value, tokens, opts)

    {:bin_element, anno, value, size, tsl}
    |> pass_tokens(tokens)
  end

  @doc """
  Iterate over the list in abstract code format and runs mapper on each element 
  """
  @spec cons_mapper(form(), [token()], options()) :: {form(), tokens()}
  def cons_mapper({:cons, anno, value, tail}, tokens, opts) do
    {:ok, _, anno, opts, has_line?} = get_line(anno, opts)

    {anno, opts} = update_line_from_tokens(tokens, anno, opts, has_line?)

    {new_value, tokens} = mapper(value, tokens, opts)

    {tail, tokens} = cons_mapper(tail, tokens, opts)

    {:cons, anno, new_value, tail}
    |> pass_tokens(tokens)
  end

  def cons_mapper(other, tokens, opts), do: mapper(other, tokens, opts)

  @doc """
  Update form anno with location taken from the corresponding token, if found.
  Otherwise return form unchanged.
  """
  @spec specify_line(form(), [token()], options()) :: {form(), [token()]}
  def specify_line(form, tokens, opts) do
    if not :erl_anno.generated(elem(form, 1)) do
      {:ok, end_line} = Keyword.fetch(opts, :end_line)

      res = drop_tokens_while(tokens, end_line, &(!match_token_to_form(&1, form)))

      case res do
        [token | tokens] ->
          {take_loc_from_token(token, form), tokens}

        [] ->
          {form, tokens}
      end
    else
      {form, tokens}
    end
  end

  # Private Helpers

  @spec match_token_to_form(token(), form()) :: boolean()
  defp match_token_to_form({:int, {l1, _, v1}, _}, {:integer, l2, v2}) do
    l2 = :erl_anno.line(l2)
    l2 <= l1 && v1 == v2
  end

  defp match_token_to_form({:char, {l1, _, _}, v1}, {:integer, l2, v2}) do
    l2 = :erl_anno.line(l2)
    l2 <= l1 && v1 == v2
  end

  defp match_token_to_form({:flt, {l1, _, v1}, _}, {:float, l2, v2}) do
    l2 = :erl_anno.line(l2)
    l2 <= l1 && v1 == v2
  end

  defp match_token_to_form({:atom, {l1, _, _}, v1}, {:atom, l2, v2}) do
    l2 = :erl_anno.line(l2)
    l2 <= l1 && v1 == v2
  end

  defp match_token_to_form({:alias, {l1, _, _}, v1}, {:atom, l2, v2}) do
    l2 = :erl_anno.line(l2)
    l2 <= l1 && v1 == v2
  end

  defp match_token_to_form({:kw_identifier, {l1, _, _}, v1}, {:atom, l2, v2}) do
    l2 = :erl_anno.line(l2)
    l2 <= l1 && v1 == v2
  end

  defp match_token_to_form({:list_string, {l1, _, _}, [v1]}, {:cons, l2, _, _} = cons) do
    v2 = cons_to_charlist(cons)
    l2 <= l1 && to_charlist(v1) == v2
  end

  # BINARY
  defp match_token_to_form(
         {:bin_string, {l1, _, _}, [v1]},
         {:bin, l2, [{:bin_element, _, {:string, _, v2}, :default, :default}]}
       ) do
    # string
    l2 <= l1 && :binary.bin_to_list(v1) == v2
  end

  defp match_token_to_form({:str, _, v}, {:string, _, v1}) do
    to_charlist(v) == v1
  end

  defp match_token_to_form({true, {l1, _, _}}, {:atom, l2, true}) do
    l2 <= l1
  end

  defp match_token_to_form({false, {l1, _, _}}, {:atom, l2, false}) do
    l2 <= l1
  end

  defp match_token_to_form(_, _) do
    false
  end

  @spec take_loc_from_token(token(), form()) :: form()
  defp take_loc_from_token({:int, {line, _, _}, _}, {:integer, _, value}) do
    {:integer, line, value}
  end

  defp take_loc_from_token({:char, {line, _, _}, _}, {:integer, _, value}) do
    {:integer, line, value}
  end

  defp take_loc_from_token({:flt, {line, _, _}, _}, {:float, _, value}) do
    {:float, line, value}
  end

  defp take_loc_from_token({:atom, {line, _, _}, _}, {:atom, _, value}) do
    {:atom, line, value}
  end

  defp take_loc_from_token({:alias, {line, _, _}, _}, {:atom, _, value}) do
    {:atom, line, value}
  end

  defp take_loc_from_token({:kw_identifier, {line, _, _}, _}, {:atom, _, value}) do
    {:atom, line, value}
  end

  defp take_loc_from_token({:list_string, {l1, _, _}, _}, {:cons, _, _, _} = charlist) do
    charlist_set_loc(charlist, l1)
  end

  defp take_loc_from_token(
         {:bin_string, {l1, _, _}, _},
         {:bin, _, [{:bin_element, _, {:string, _, v2}, :default, :default}]}
       ) do
    {:bin, l1, [{:bin_element, l1, {:string, l1, v2}, :default, :default}]}
  end

  defp take_loc_from_token({:str, _, _}, {:string, loc, v2}) do
    {:string, loc, v2}
  end

  defp take_loc_from_token({true, {line, _, _}}, {:atom, _, true}) do
    {:atom, line, true}
  end

  defp take_loc_from_token({false, {line, _, _}}, {:atom, _, false}) do
    {:atom, line, false}
  end

  defp take_loc_from_token(_, _), do: nil

  def cons_to_charlist({nil, _}), do: []

  def cons_to_charlist({:cons, _, {:integer, _, value}, tail}) do
    [value | cons_to_charlist(tail)]
  end

  def charlist_set_loc({:cons, _, {:integer, _, value}, tail}, loc) do
    {:cons, loc, {:integer, loc, value}, charlist_set_loc(tail, loc)}
  end

  def charlist_set_loc({nil, loc}, _), do: {nil, loc}

  def put_line(anno, opts, line) do
    {:erl_anno.set_line(line, anno), Keyword.put(opts, :line, line)}
  end

  def update_line_from_tokens([token | _], anno, opts, false) do
    line = get_line_from_token(token)
    put_line(anno, opts, line)
  end

  def update_line_from_tokens(_, anno, opts, _) do
    {anno, opts}
  end

  defp get_line(anno, opts) do
    case :erl_anno.line(anno) do
      0 ->
        case Keyword.fetch(opts, :line) do
          {:ok, line} ->
            anno = :erl_anno.set_line(line, anno)
            {:ok, line, anno, opts, false}

          err ->
            err
        end

      line ->
        opts = Keyword.put(opts, :line, line)
        {:ok, line, anno, opts, true}
    end
  end

  @spec prepare_forms_order(forms()) :: forms()
  defp prepare_forms_order(forms) do
    forms
    |> Enum.sort(fn l, r -> elem(l, 0) == elem(r, 0) and elem(l, 1) > elem(r, 1) end)
    |> Enum.reverse()
  end

  defp set_form_end_line(opts, form, forms) do
    case Enum.find(forms, fn f ->
           anno = elem(f, 1)

           # Maybe should try to go deeper when generated and try to obtain 
           # the line from the first child. It should work for sure for clauses, 
           # but it has to be in the right order (e.g. if clauses are reversed)
           :erl_anno.line(anno) > 0 and not :erl_anno.generated(anno)
         end) do
      nil ->
        opts

      next_form ->
        current_line = :erl_anno.line(elem(form, 1))
        next_line = :erl_anno.line(elem(next_form, 1))

        if current_line == next_line do
          Keyword.put(opts, :end_line, next_line + 1)
        else
          Keyword.put(opts, :end_line, next_line)
        end
    end
  end

  @spec pass_tokens(any(), tokens()) :: {any(), tokens()}
  defp pass_tokens(form, tokens) do
    {form, tokens}
  end
end
