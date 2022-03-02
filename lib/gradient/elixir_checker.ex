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

  Correct specs location:
    ```
    @spec convert(integer()) :: float()
    def convert(int) when is_integer(int), do: int / 1
    @spec convert(atom()) :: binary()
    def convert(atom) when is_atom(atom), do: to_string(atom)
    ```

  Incorrect specs location:
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
    |> Stream.filter(&has_line/1)
    |> Enum.sort(&(elem(&1, 2) < elem(&2, 2)))
    |> Enum.reduce({nil, []}, fn
      {:fun, fna, _} = fun, {{:spec, {n, a} = sna, anno}, errors} when fna != sna ->
        # Spec name doesn't match the function name
        {fun, [{:spec_error, :wrong_spec_name, anno, n, a} | errors]}

      {:spec, {n, a}, anno} = s1, {{:spec, _, _}, errors} ->
        # Only one spec per function clause is allowed
        {s1, [{:spec_error, :spec_after_spec, anno, n, a} | errors]}

      x, {_, errors} ->
        {x, errors}
    end)
    |> elem(1)
    |> Enum.map(&{file, &1})
  end

  # Filter out __info__ generated function
  def has_line(form), do: :erl_anno.line(elem(form, 2)) > 1

  def is_fun_or_spec?({:attribute, _, :spec, _}), do: true
  def is_fun_or_spec?({:function, _, _, _, _}), do: true
  def is_fun_or_spec?(_), do: false

  @spec simplify_form(:erl_parse.abstract_form()) ::
          Enumerable.t({:spec | :fun, {atom(), integer()}, :erl_anno.anno()})
  def simplify_form({:attribute, _, :spec, {{name, arity}, types}}) do
    Stream.map(types, &{:spec, {name, arity}, elem(&1, 1)})
  end

  def simplify_form({:function, _, name, arity, clauses}) do
    Stream.map(clauses, &{:fun, {name, arity}, elem(&1, 1)})
  end
end
