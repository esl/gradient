defmodule ExamplesCompiler do
  @build_path "test/examples/_build/"
  @erl_build_path "test/examples/erlang/_build/"

  @version (case System.version() do
              v when v >= "1.13" -> 1.13
              v when v >= "1.12" -> 1.12
              v when v >= "1.11" -> 1.11
            end)

  def compile(pattern) do
    case File.mkdir(@build_path) do
      :ok ->
        paths =
          Path.wildcard(pattern)
          |> filter_too_new_files()

        Kernel.ParallelCompiler.compile_to_path(paths, @build_path)
        :ok

      _ ->
        :error
    end
  end

  def erl_compile(pattern) do
    case File.mkdir(@erl_build_path) do
      :ok ->
        pattern
        |> Path.wildcard()
        |> Enum.each(fn p ->
          :compile.file(to_charlist(p), [:debug_info, {:outdir, to_charlist(@erl_build_path)}])
        end)

      _ ->
        :error
    end
  end

  def excluded_version_tags do
    case @version do
      1.11 ->
        [:ex_gt_1_11, :ex_lt_1_11]

      1.12 ->
        [:ex_lt_1_11, :ex_lt_1_12, :ex_gt_1_12, :ex_gt_1_13]

      1.13 ->
        [:ex_lt_1_11, :ex_lt_1_12, :ex_lt_1_13, :ex_gt_1_13]
    end
  end

  defp filter_too_new_files(paths) do
    case @version do
      1.13 ->
        paths

      1.12 ->
        drop_versions(paths, ["1.13"])

      1.11 ->
        drop_versions(paths, ["1.12", "1.13"])
    end
  end

  defp drop_versions(paths, versions) do
    Enum.filter(paths, &(not String.contains?(&1, versions)))
  end
end

ExamplesCompiler.compile("test/examples/**/*.ex")
exlcude = ExamplesCompiler.excluded_version_tags()

ExamplesCompiler.erl_compile("test/examples/erlang/**/*.erl")

ExUnit.start(exclude: exlcude)
