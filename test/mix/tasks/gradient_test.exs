defmodule Mix.Tasks.GradientTest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  @no_errors_msg "No errors found!"

  @examples_path "test/examples"
  @build_path Path.join([@examples_path, "_build"])

  @s_wrong_ret_beam Path.join(@build_path, "Elixir.SWrongRet.beam")
  @s_wrong_ret_ex Path.join([@examples_path, "type", "s_wrong_ret.ex"])

  setup do
    Application.put_env(:gradient, :__system_halt__, fn signal ->
      send(self(), {:system_halt, signal})
    end)

    on_exit(fn ->
      Application.delete_env(:gradient, :__system_halt__)
    end)

    :ok
  end

  test "--no-compile option" do
    info = "Compiling project..."

    output = run_task([@s_wrong_ret_beam])
    assert String.contains?(output, info)

    output = run_task(["--no-compile", "--", @s_wrong_ret_beam])
    assert not String.contains?(output, info)

    assert_receive {:system_halt, 1}
  end

  test "path to the beam file" do
    output = run_task(test_opts([@s_wrong_ret_beam]))
    assert 3 == String.split(output, @s_wrong_ret_ex) |> length()

    assert_receive {:system_halt, 1}
  end

  test "path to the ex file" do
    output = run_task(test_opts([@s_wrong_ret_ex]))
    assert 3 == String.split(output, @s_wrong_ret_ex) |> length()

    assert_receive {:system_halt, 1}
  end

  test "no_fancy option" do
    output = run_task(test_opts([@s_wrong_ret_beam]))
    assert String.contains?(output, "The integer on line")
    assert String.contains?(output, "The tuple on line")

    assert_receive {:system_halt, 1}

    output = run_task(test_opts(["--no-fancy", "--", @s_wrong_ret_beam]))
    assert String.contains?(output, "The integer \e[33m1\e[0m on line")
    assert String.contains?(output, "The tuple \e[33m{:ok, []}\e[0m on line")

    assert_receive {:system_halt, 1}
  end

  describe "colors" do
    test "no_colors option" do
      output = run_task(test_opts([@s_wrong_ret_beam]))
      assert String.contains?(output, IO.ANSI.cyan())
      assert String.contains?(output, IO.ANSI.red())
      assert_receive {:system_halt, 1}

      output = run_task(test_opts(["--no-colors", "--", @s_wrong_ret_beam]))
      assert not String.contains?(output, IO.ANSI.cyan())
      assert String.contains?(output, IO.ANSI.red())
      assert_receive {:system_halt, 1}
    end

    test "--expr-color and --type-color option" do
      output =
        run_task(
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
      assert_receive {:system_halt, 1}
    end

    test "--underscore_color option" do
      output =
        run_task(
          test_opts([
            "--underscore-color",
            "green",
            "--",
            @s_wrong_ret_beam
          ])
        )

      assert String.contains?(output, IO.ANSI.green())
      assert String.contains?(output, IO.ANSI.red())
      assert_receive {:system_halt, 1}
    end
  end

  test "--no-gradualizer-check option" do
    output = run_task(test_opts(["--no-gradualizer-check", "--", @s_wrong_ret_beam]))

    assert String.contains?(output, @no_errors_msg)
    refute_receive {:system_halt, 1}
  end

  test "--no-ex-check option" do
    beam = Path.join(@build_path, "Elixir.SpecMixed.beam")
    ex_spec_error_msg = "The spec encode/1 on line"

    output = run_task(test_opts([beam]))
    assert String.contains?(output, ex_spec_error_msg)

    output = run_task(test_opts(["--no-ex-check", "--", beam]))
    assert not String.contains?(output, ex_spec_error_msg)
    assert_receive {:system_halt, 1}
  end

  @tag :ex_lt_1_13
  test "--no-specify option" do
    output = run_task(test_opts([@s_wrong_ret_beam]))
    assert String.contains?(output, "on line 3")
    assert String.contains?(output, "on line 6")
    assert_receive {:system_halt, 1}

    output = run_task(test_opts(["--no-specify", "--", @s_wrong_ret_beam]))
    assert String.contains?(output, "on line 0")
    assert not String.contains?(output, "on line 3")
    assert not String.contains?(output, "on line 6")
    assert_receive {:system_halt, 1}
  end

  test "--stop-on-first-error option" do
    output = run_task(test_opts(["--stop-on-first-error", "--", @s_wrong_ret_beam]))

    assert 2 == String.split(output, @s_wrong_ret_ex) |> length()
    assert_receive {:system_halt, 1}
  end

  test "--fmt-location option" do
    output = run_task(test_opts(["--fmt-location", "none", "--", @s_wrong_ret_beam]))

    assert String.contains?(output, "s_wrong_ret.ex: The integer is expected to have type")
    assert_receive {:system_halt, 1}

    output = run_task(test_opts(["--fmt-location", "brief", "--", @s_wrong_ret_beam]))

    assert String.contains?(output, "s_wrong_ret.ex:3: The integer is expected to have type")
    assert_receive {:system_halt, 1}

    output = run_task(test_opts(["--fmt-location", "verbose", "--", @s_wrong_ret_beam]))

    assert String.contains?(
             output,
             "s_wrong_ret.ex: The integer on line 3 is expected to have type"
           )

    assert_receive {:system_halt, 1}
  end

  test "--no-deps option" do
    info = "Loading deps..."

    output = run_task(["--no-compile", "--", @s_wrong_ret_beam])
    assert String.contains?(output, info)
    assert_receive {:system_halt, 1}

    output = run_task(["--no-compile", "--no-deps", "--", @s_wrong_ret_beam])
    assert not String.contains?(output, info)
    assert_receive {:system_halt, 1}
  end

  test "--infer option" do
    beam = Path.join(@build_path, "Elixir.ListInfer.beam")
    output = run_task(test_opts([beam]))
    assert String.contains?(output, @no_errors_msg)
    refute_receive {:system_halt, 1}

    output = run_task(test_opts(["--infer", "--", beam]))
    assert not String.contains?(output, @no_errors_msg)
    assert String.contains?(output, "list_infer.ex: The variable on line 4")
    assert_receive {:system_halt, 1}
  end

  test "--source-path option" do
    ex_file = "wrong_ret.ex"

    output = run_task(test_opts(["--source-path", ex_file, "--", @s_wrong_ret_beam]))

    assert not String.contains?(output, @s_wrong_ret_ex)
    assert String.contains?(output, ex_file)
    assert_receive {:system_halt, 1}
  end

  test "counts errors" do
    assert run_task([@s_wrong_ret_beam]) =~ "Total errors: 2"
    assert_receive {:system_halt, 1}

    assert run_task([@s_wrong_ret_beam, @s_wrong_ret_ex]) =~ "Total errors: 4"
    assert_receive {:system_halt, 1}
  end

  test "dependent modules are loaded" do
    assert run_task([@examples_path <> "/dependent_modules.ex"]) =~ "No errors found!"
  end

  # def run_task(args), do: capture_io(fn -> Mix.Tasks.Gradient.run(args) end)
  def run_task(args) do
    capture_io(fn ->
      capture_io(:stderr, fn ->
        Mix.Tasks.Gradient.run(args)
      end)
    end)
  end

  def test_opts(opts), do: ["--no-comile", "--no-deps"] ++ opts
end
