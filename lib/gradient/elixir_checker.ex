defmodule Gradient.ElixirChecker do
  @moduledoc ~s"""
  Provide checks specific to Elixir that complement type checking delivered by Gradient.

  Options:
  - {`ex_check`, boolean()}: whether to use checks specific only to Elixir.
  """

  @spec check([:erl_parse.abstract_form()], keyword()) :: [{:file.filename(), any()}]
  def check(forms, opts) do
    if Keyword.get(opts, :ex_check, true) do
      check_spec(forms)
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
  @spec check_spec([:erl_parse.abstract_form()]) :: [{:file.filename(), any()}]
  def check_spec([{:attribute, _, :file, {file, _}} | forms]) do
    forms
    |> Stream.filter(&is_fun_or_spec?/1)
    |> Stream.map(&simplify_form/1)
    |> Stream.concat()
    |> Stream.filter(&is_not_generated?/1)
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
    |> Enum.map(&{file, &1})
    |> Enum.reverse()
  end

  # Filter out __info__ and other generated functions with the same name pattern
  def is_not_generated?({_, {name, _}, _}) do
    name_str = Atom.to_string(name)
    not (String.starts_with?(name_str, "__") and String.ends_with?(name_str, "__"))
  end

  def is_fun_or_spec?({:attribute, _, :spec, _}), do: true
  def is_fun_or_spec?({:function, _, _, _, _}), do: true
  def is_fun_or_spec?(_), do: false

  @spec simplify_form(:erl_parse.abstract_form()) ::
          Enumerable.t({:spec | :fun, {atom(), integer()}, :erl_anno.anno()})
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
    Enum.all?(vars, fn {:var, anno, _} -> :erl_anno.generated(anno) end)
  end
end
