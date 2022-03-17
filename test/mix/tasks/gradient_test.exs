defmodule Mix.Tasks.GradientTest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  @no_problems_msg "No problems found!"

  @examples_path "test/examples/"
  @type_path Path.join([@examples_path, "type"])

  @s_wrong_ret_beam "Elixir.SWrongRet.beam"
  @s_wrong_ret_ex "s_wrong_ret.ex"

  test "--no-compile option" do
    info = "Compiling project..."

    output = run_task(@type_path, [@s_wrong_ret_beam])
    assert String.contains?(output, info)

    dir = Path.join(@type_path, "_build")
    :os.cmd(String.to_charlist("rm -Rf " <> dir))

    output = run_task(@type_path, ["--no-compile", "--", @s_wrong_ret_beam])
    assert not String.contains?(output, info)
  end

  test "path to the beam file" do
    output = run_task(@type_path, test_opts([@s_wrong_ret_beam]))
    assert 3 == String.split(output, @s_wrong_ret_ex) |> length()
  end

  test "path to the ex file" do
    output = run_task(@type_path, test_opts([@s_wrong_ret_ex]))
    assert 3 == String.split(output, @s_wrong_ret_ex) |> length()
  end

  test "no_fancy option" do
    output = run_task(@type_path, test_opts([@s_wrong_ret_beam]))
    assert String.contains?(output, "The integer on line")
    assert String.contains?(output, "The tuple on line")

    output = run_task(@type_path, test_opts(["--no-fancy", "--", @s_wrong_ret_beam]))
    assert String.contains?(output, "The integer \e[33m1\e[0m on line")
    assert String.contains?(output, "The tuple \e[33m{:ok, []}\e[0m on line")
  end

  describe "colors" do
    test "no_colors option" do
      output = run_task(@type_path, test_opts([@s_wrong_ret_beam]))
      assert String.contains?(output, IO.ANSI.cyan())
      assert String.contains?(output, IO.ANSI.red())

      output = run_task(@type_path, test_opts(["--no-colors", "--", @s_wrong_ret_beam]))
      assert not String.contains?(output, IO.ANSI.cyan())
      assert not String.contains?(output, IO.ANSI.red())
    end

    test "--expr-color and --type-color option" do
      output =
        run_task(
          @type_path,
          test_opts([
            "--no-fancy",
            "--expr-color",
            "green",
            "--type-color",
            "magenta",
            "--",
            @s_wrong_ret_beam
          ])
        )

      assert String.contains?(output, IO.ANSI.green())
      assert String.contains?(output, IO.ANSI.magenta())
    end

    test "--underscore_color option" do
      output =
        run_task(
          @type_path,
          test_opts([
            "--underscore-color",
            "green",
            "--",
            @s_wrong_ret_beam
          ])
        )

      assert String.contains?(output, IO.ANSI.green())
      assert not String.contains?(output, IO.ANSI.red())
    end
  end

  test "--no-gradualizer-check option" do
    output = run_task(@type_path, test_opts(["--no-gradualizer-check", "--", @s_wrong_ret_beam]))

    assert String.contains?(output, "No problems found!")
  end

  test "--no-ex-check option" do
    beam = "Elixir.SpecAfterSpec.beam"
    ex_spec_error_msg = "The spec convert_a/1 on line"

    output = run_task(@examples_path, test_opts([beam]))
    assert String.contains?(output, ex_spec_error_msg)

    output = run_task(@examples_path, test_opts(["--no-ex-check", "--", beam]))
    assert not String.contains?(output, ex_spec_error_msg)
  end

  @tag if(System.version() >= "1.13", do: :skip, else: :ok)
  test "--no-specify option" do
    output = run_task(@type_path, test_opts([@s_wrong_ret_beam]))
    assert String.contains?(output, "on line 3")
    assert String.contains?(output, "on line 6")

    output = run_task(@type_path, test_opts(["--no-specify", "--", @s_wrong_ret_beam]))
    assert String.contains?(output, "on line 0")
    assert not String.contains?(output, "on line 3")
    assert not String.contains?(output, "on line 6")
  end

  test "--stop-on-first-error option" do
    output = run_task(@type_path, test_opts(["--stop-on-first-error", "--", @s_wrong_ret_beam]))

    assert 2 == String.split(output, @s_wrong_ret_ex) |> length()
  end

  test "--fmt-location option" do
    output = run_task(@type_path, test_opts(["--fmt-location", "none", "--", @s_wrong_ret_beam]))

    assert String.contains?(output, "s_wrong_ret.ex: The integer is expected to have type")

    output = run_task(@type_path, test_opts(["--fmt-location", "brief", "--", @s_wrong_ret_beam]))

    assert String.contains?(output, "s_wrong_ret.ex:3: The integer is expected to have type")

    output =
      run_task(@type_path, test_opts(["--fmt-location", "verbose", "--", @s_wrong_ret_beam]))

    assert String.contains?(
             output,
             "s_wrong_ret.ex: The integer on line 3 is expected to have type"
           )
  end

  test "--no-deps option" do
    info = "Loading deps..."

    output = run_task(@type_path, ["--no-compile", "--", @s_wrong_ret_beam])
    assert String.contains?(output, info)

    output = run_task(@type_path, ["--no-compile", "--no-deps", "--", @s_wrong_ret_beam])
    assert not String.contains?(output, info)
  end

  test "--infer option" do
    beam = "Elixir.ListInfer.beam"
    output = run_task(@type_path, test_opts([beam]))
    assert String.contains?(output, @no_problems_msg)

    output = run_task(@type_path, test_opts(["--infer", "--", beam]))
    assert not String.contains?(output, @no_problems_msg)
    assert String.contains?(output, "list_infer.ex: The variable on line 4")
  end

  test "--code-path option" do
    ex_file = "wrong_ret.ex"

    output = run_task(@type_path, test_opts(["--code-path", ex_file, "--", @s_wrong_ret_beam]))

    assert not String.contains?(output, @s_wrong_ret_ex)
    assert String.contains?(output, ex_file)
  end

  def run_task(rel_path, args) do
    run_in_path(rel_path, fn ->
      capture_io(fn -> Mix.Tasks.Gradient.run(args) end)
    end)
  end

  def run_in_path(path, fun) do
    cwd = File.cwd!()
    File.cd(path)
    res = fun.()
    File.cd(cwd)
    res
  end

  def test_opts(opts) do
    ["--no-comile", "--no-deps"] ++ opts
  end
end
