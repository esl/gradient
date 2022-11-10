defmodule Gradient.ElixirChecker do
  @moduledoc ~s"""
  Provide checks specific to Elixir that complement type checking delivered by Gradient.

  Options:
  - {`ex_check`, boolean()}: whether to use checks specific only to Elixir.
  """

  @type env() :: Gradient.env()
  @type opts :: [env: env(), ex_check: boolean()]
  @type simplified_form :: {:spec | :fun, {atom(), integer()}, :erl_anno.anno()}

  @spec check([:erl_parse.abstract_form()], opts()) :: [{:file.filename(), any()}]
  def check(forms, opts) do
    if Keyword.get(opts, :ex_check, true) do
      check_spec(forms, opts)
    else
      []
    end
  end

  @doc ~s"""
  Check if all specs are exactly before the function that they specify
  and if there is only one spec per function clause.

  Correct spec locations:
    ```
    @spec convert(integer()) :: float()
    def convert(int) when is_integer(int), do: int / 1

    @spec convert(atom()) :: binary()
    def convert(atom) when is_atom(atom), do: to_string(atom)
    ```

  Incorrect spec locations:
    - More than one spec above function clause.
    ```
    @spec convert(integer()) :: float()
    @spec convert(atom()) :: binary()
    def convert(int) when is_integer(int), do: int / 1

    def convert(atom) when is_atom(atom), do: to_string(atom)
    ```

    - Spec name doesn't match the function name.
    ```
    @spec last_two(atom()) :: atom()
    def last_three(:ok) do
      :ok
    end
    ```
  """
  @spec check_spec([:erl_parse.abstract_form()], opts()) :: [{:file.filename(), any()}]
  def check_spec([{:attribute, _, :file, {file, _}} | forms], opts) do
    %{tokens_present: tokens_present, macro_lines: macro_lines} = opts[:env]

    prep_forms =
      forms
      |> Stream.filter(&is_fun_or_spec?(&1, macro_lines))
      |> Stream.map(&simplify_form/1)
      |> Stream.concat()
      |> Stream.filter(&is_not_generated?/1)

    errors =
      prep_forms
      |> remove_injected_forms(not tokens_present)
      |> Enum.sort(&(elem(&1, 2) < elem(&2, 2)))
      |> Enum.reduce({nil, []}, fn
        {:fun, {n, :def}, _}, {{:spec, {sn, _}, _}, _} = acc when n == sn ->
          # skip clauses generated for default arguments
          acc

        {:fun, fna, _} = fun, {{:spec, {n, a} = sna, anno}, errors} when fna != sna ->
          # Spec name doesn't match the function name
          {fun, [{:spec_error, :wrong_spec_name, anno, n, a} | errors]}

        {:spec, {n, a}, anno} = s1, {{:spec, {n2, a2}, _}, errors} when n != n2 or a != a2 ->
          # Specs with diffrent name/arity are mixed
          {s1, [{:spec_error, :mixed_specs, anno, n, a} | errors]}

        x, {_, errors} ->
          {x, errors}
      end)
      |> elem(1)

    no_specs_warn =
      case opts[:warn_missing_spec] do
        :exported ->
          forms
          |> Enum.find([], &exports/1)
          |> elem(3)
          |> List.delete_at(0)
          |> Keyword.keys()
          |> warn_missing_spec(prep_forms)

        :all ->
          warn_missing_spec([], prep_forms)

        _ ->
          []
      end

    (errors ++ no_specs_warn)
    |> Enum.map(&{file, &1})
    |> Enum.reverse()
  end

  # Filter out __info__ and other generated functions with the same name pattern
  def is_not_generated?({_, {name, _}, _}) do
    name_str = Atom.to_string(name)
    not (String.starts_with?(name_str, "__") and String.ends_with?(name_str, "__"))
  end

  # The forms injected by `__using__` macro inherit the line from `use` keyword.
  def is_fun_or_spec?({:attribute, anno, :spec, _}, ml), do: :erl_anno.line(anno) not in ml
  def is_fun_or_spec?({:function, anno, _, _, _}, ml), do: :erl_anno.line(anno) not in ml
  def is_fun_or_spec?(_, _), do: false

  @doc """
  Returns a stream of simplified forms in the format defined by type `simplified_form/1`
  """
  @spec simplify_form(:erl_parse.abstract_form()) :: Enumerable.t()
  def simplify_form({:attribute, _, :spec, {{name, arity}, types}}) do
    Stream.map(types, &{:spec, {name, arity}, elem(&1, 1)})
  end

  def simplify_form({:function, anno, name, arity, clauses}) do
    Stream.map(clauses, &default_args_clause(anno, name, arity, &1))
  end

  def default_args_clause(anno, name, arity, clause) do
    with {:clause, ^anno, vars, [], [{:call, ^anno, {:atom, ^anno, ^name}, _}]} <- clause,
         true <- all_vars_generated?(vars) do
      {:fun, {name, :def}, anno}
    else
      _ ->
        {:fun, {name, arity}, elem(clause, 1)}
    end
  end

  def all_vars_generated?(vars) do
    Enum.all?(vars, fn
      {:var, anno, _} -> :erl_anno.generated(anno)
      _ -> false
    end)
  end

  # When tokens were not present to detect macro_lines, the forms without unique
  # lines can be removed.
  def remove_injected_forms(forms, true) do
    forms
    |> Enum.group_by(fn {_, _, line} -> line end)
    |> Enum.filter(fn {_, fs2} -> length(fs2) == 1 end)
    |> Enum.flat_map(fn {_, fs2} -> fs2 end)
  end

  def remove_injected_forms(forms, false), do: forms

  defp warn_missing_spec(to_filter, forms) do
    all_fnas_specs =
      Enum.reduce(forms, %{:fun => [], :spec => []}, fn
        {:fun, {name, _}, _}, %{fun: fnas} = acc -> %{acc | fun: [name | fnas]}
        {:spec, {name, _}, _}, %{spec: fnas} = acc -> %{acc | spec: [name | fnas]}
        _, acc -> acc
      end)

    ret = (all_fnas_specs[:fun] -- all_fnas_specs[:spec]) -- to_filter
    ret = MapSet.new(ret)

    Enum.reduce(forms, [], fn
      {:fun, {n, a}, anno}, acc ->
        if Enum.member?(ret, n) do
          [{:spec_error, :no_spec, anno, n, a} | acc]
        else
          acc
        end

      _, acc ->
        acc
    end)
  end

  defp exports({_, _, :export, _}), do: true
  defp exports(_), do: false
end
