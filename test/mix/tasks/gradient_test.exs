defmodule Mix.Tasks.GradientTest do
  # Async false since these tests use the file system
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  @no_errors_msg "No errors found!"

  @examples_path "test/examples"
  @build_path Path.join([@examples_path, "_build"])

  @s_wrong_ret_beam Path.join(@build_path, "Elixir.SWrongRet.beam")
  @s_wrong_ret_ex Path.join([@examples_path, "type", "s_wrong_ret.ex"])

  @simple_umbrella_app_path "examples/simple_umbrella_app"
  @simple_phoenix_app_path "examples/simple_phoenix_app"
  @use_tesla_app_path "test/examples/use_tesla"

  setup_all do
    # Run `mix deps.get` on all the projects we'll be running gradient on. This
    # happens in setup_all so it's only run once per project path, rather than
    # once per test.
    [
      @simple_umbrella_app_path,
      @simple_phoenix_app_path
    ]
    |> Enum.each(&mix_deps_get/1)

    :ok
  end

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
    beam = Path.join(@build_path, "Elixir.SpecWrongName.beam")
    ex_spec_error_msg = "The spec convert/1"

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

  test "--solve-constraints option" do
    ex_file = "polymorphic.ex"
    beam = Path.join(@build_path, "Elixir.Polymorphic.beam")

    output = run_task(test_opts(["--solve-constraints", "--", beam]))

    assert String.contains?(output, ex_file)
    assert String.contains?(output, "Total errors: 2")
    assert String.contains?(output, "Lower bound")
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

  describe "Umbrella project app filtering:" do
    # Templates for dynamically creating variations on the umbrella/subapp
    # mix.exs config files at runtime
    @umbrella_mix_exs """
    defmodule SimpleUmbrellaApp.MixProject do
      use Mix.Project

      def project do
        [
          apps_path: "apps",
          version: "0.1.0",
          start_permanent: Mix.env() == :prod,
          deps: deps(),
          <%= if not no_config do %>
            gradient: [
              <%= if enabled != nil do %>
                enabled: <%= enabled %>,
              <% end %>

              <%= if overrides != nil do %>
                file_overrides: <%= overrides %>,
              <% end %>
            ]
          <% end %>
        ]
      end

      defp deps do
        [{:gradient, path: "../../", override: true}]
      end
    end
    """

    @subapp_mix_exs """
    defmodule App<%= String.upcase(app) %>.MixProject do
      use Mix.Project

      def project do
        [
          app: :app_<%= app %>,
          version: "0.1.0",
          build_path: "../../_build",
          config_path: "../../config/config.exs",
          deps_path: "../../deps",
          lockfile: "../../mix.lock",
          elixir: "~> 1.12",
          start_permanent: Mix.env() == :prod,
          deps: deps(),
          <%= if not no_config do %>
            gradient: [
              <%= if enabled != nil do %>
                enabled: <%= enabled %>,
              <% end %>

              <%= if overrides != nil do %>
                file_overrides: <%= overrides %>,
              <% end %>
            ]
          <% end %>
        ]
      end

      <%= if app == "b" do %>
        defp deps, do: [{:app_a, in_umbrella: true}]
      <% else %>
        defp deps, do: []
      <% end %>
    end
    """

    @umbrella_app_path "examples/simple_umbrella_app"
    @umbrella_mix @umbrella_app_path <> "/mix.exs"
    @umbrella_app_a_mix @umbrella_app_path <> "/apps/app_a/mix.exs"
    @umbrella_app_b_mix @umbrella_app_path <> "/apps/app_b/mix.exs"

    setup context do
      umbrella_mix_contents = File.read!(@umbrella_mix)
      app_a_mix_contents = File.read!(@umbrella_app_a_mix)
      app_b_mix_contents = File.read!(@umbrella_app_b_mix)

      on_exit(fn ->
        # Put back the original file contents at the end of the test
        File.write!(@umbrella_mix, umbrella_mix_contents)
        File.write!(@umbrella_app_a_mix, app_a_mix_contents)
        File.write!(@umbrella_app_b_mix, app_b_mix_contents)
      end)

      # Edit files if specified in config
      context |> Map.get(:edit_files, %{}) |> edit_files()

      # Get test configs from context
      umbrella_mix = Map.get(context, :umbrella, %{}) |> prep_config()
      app_a_mix = Map.get(context, :app_a, %{}) |> Map.put(:app, "a") |> prep_config()
      app_b_mix = Map.get(context, :app_b, %{}) |> Map.put(:app, "b") |> prep_config()

      # Write new mix.exs file contents for duration of test
      File.write!(@umbrella_mix, EEx.eval_string(@umbrella_mix_exs, umbrella_mix))
      File.write!(@umbrella_app_a_mix, EEx.eval_string(@subapp_mix_exs, app_a_mix))
      File.write!(@umbrella_app_b_mix, EEx.eval_string(@subapp_mix_exs, app_b_mix))
    end

    # Merge in default configs, and convert map to keyword list
    defp prep_config(mix_exs_config) do
      Map.merge(
        %{
          no_config: false,
          enabled: nil,
          overrides: nil
        },
        mix_exs_config
      )
      |> Keyword.new()
    end

    defp edit_files(files) do
      for {filename, enabled?} <- files do
        filename = @umbrella_app_path <> "/apps/" <> filename

        magic_comment =
          if enabled?, do: "# gradient:enable-for-file\n", else: "# gradient:disable-for-file\n"

        file_contents = File.read!(filename)
        updated_file_contents = magic_comment <> file_contents
        File.write!(filename, updated_file_contents)

        on_exit(fn ->
          File.write!(filename, file_contents)
        end)
      end
    end

    # Run the task on the umbrella app, and extract which files it ran on
    defp run_task_and_return_files() do
      output = run_shell_task("examples/simple_umbrella_app", ["--print-filenames"])

      # Parse the output and figure out which files it said it ran on
      output
      |> String.split("\n")
      |> Enum.reduce(
        %{state: :not_started, apps_files: %{}, curr_app: nil},
        fn line, %{state: state, apps_files: apps_files, curr_app: curr_app} = acc ->
          case state do
            # Looking for the string "Typechecking files..." to start
            :not_started ->
              if line == "Files to check:" do
                %{acc | state: :started}
              else
                acc
              end

            :started ->
              case line do
                # Change current app
                "Files in app " <> app_name_and_colon ->
                  # get rid of colon on the end
                  app_name = String.replace(app_name_and_colon, ":", "")
                  %{acc | curr_app: app_name}

                # This line signifies the end of the file list
                "Typechecking files..." ->
                  %{acc | state: :finished}

                # Save filename to list for current app
                filename ->
                  file_list_for_app = Map.get(apps_files, curr_app, [])
                  updated_file_list = file_list_for_app ++ [filename]
                  updated_apps_files = Map.put(apps_files, curr_app, updated_file_list)
                  %{acc | apps_files: updated_apps_files}
              end

            # Already found all the files, no-op
            :finished ->
              acc
          end
        end
      )
      # Return just the list of apps/files
      |> Map.get(:apps_files)
    end

    # Strip off "_build/dev/" or "_build/test/" from the beginning of a path
    defp strip_beam_path("_build/dev/" <> path), do: path
    defp strip_beam_path("_build/test/" <> path), do: path
    defp strip_beam_path(path), do: path

    @tag umbrella: %{no_config: true}, app_a: %{no_config: true}, app_b: %{no_config: true}
    test "defaults to enabled when no gradient config in any mix.exs files" do
      assert %{"app_a" => app_a_files, "app_b" => app_b_files} = run_task_and_return_files()

      assert [
               "lib/app_a/ebin/Elixir.AppA.beam",
               "lib/app_a/ebin/Elixir.AppAHelper.beam"
             ] == Enum.map(app_a_files, &strip_beam_path/1)

      assert [
               "lib/app_b/ebin/Elixir.AppB.beam",
               "lib/app_b/ebin/Elixir.AppBHelper.beam"
             ] == Enum.map(app_b_files, &strip_beam_path/1)
    end

    @tag umbrella: %{enabled: true}, app_a: %{no_config: true}, app_b: %{no_config: true}
    test "when gradient is enabled for umbrella, checks all files" do
      assert %{"app_a" => app_a_files, "app_b" => app_b_files} = run_task_and_return_files()

      assert [
               "lib/app_a/ebin/Elixir.AppA.beam",
               "lib/app_a/ebin/Elixir.AppAHelper.beam"
             ] == Enum.map(app_a_files, &strip_beam_path/1)

      assert [
               "lib/app_b/ebin/Elixir.AppB.beam",
               "lib/app_b/ebin/Elixir.AppBHelper.beam"
             ] == Enum.map(app_b_files, &strip_beam_path/1)
    end

    @tag umbrella: %{enabled: false}, app_a: %{no_config: true}, app_b: %{no_config: true}
    test "when gradient is disabled for umbrella, doesn't check any files" do
      assert %{} == run_task_and_return_files()
    end

    @tag umbrella: %{enabled: false}, app_a: %{enabled: true}
    test "gradient can be enabled for a subapp even if disabled for umbrella" do
      assert %{"app_a" => app_a_files} = run_task_and_return_files()

      assert [
               "lib/app_a/ebin/Elixir.AppA.beam",
               "lib/app_a/ebin/Elixir.AppAHelper.beam"
             ] == Enum.map(app_a_files, &strip_beam_path/1)
    end

    @tag umbrella: %{enabled: true}, app_a: %{enabled: false}
    test "gradient can be enabled for the umbrella and disabled for a subapp" do
      assert %{"app_b" => app_b_files} = run_task_and_return_files()

      assert [
               "lib/app_b/ebin/Elixir.AppB.beam",
               "lib/app_b/ebin/Elixir.AppBHelper.beam"
             ] == Enum.map(app_b_files, &strip_beam_path/1)
    end

    @tag umbrella: %{enabled: true, overrides: true},
         edit_files: %{"app_a/lib/app_a_helper.ex" => false}
    test "individual files can be disabled" do
      assert %{"app_a" => app_a_files, "app_b" => app_b_files} = run_task_and_return_files()

      assert ["lib/app_a/ebin/Elixir.AppA.beam"] == Enum.map(app_a_files, &strip_beam_path/1)

      assert [
               "lib/app_b/ebin/Elixir.AppB.beam",
               "lib/app_b/ebin/Elixir.AppBHelper.beam"
             ] == Enum.map(app_b_files, &strip_beam_path/1)
    end

    @tag umbrella: %{enabled: false, overrides: true}, edit_files: %{"app_a/lib/app_a.ex" => true}
    test "individual files can be enabled" do
      assert %{"app_a" => app_a_files} = run_task_and_return_files()

      assert ["lib/app_a/ebin/Elixir.AppA.beam"] == Enum.map(app_a_files, &strip_beam_path/1)
    end
  end

  # Checks to make sure that Gradient passes on a simple Phoenix app, i.e. one
  # that was generated with `mix phx.new`. Such an app has been created in the
  # examples/simple_phoenix_app directory in this project.
  describe "simple Phoenix app" do
    @tag timeout: 120_000
    test "Gradient run is successful" do
      # run_shell_task asserts that the task had an exit code of 0, ensuring
      # there were no errors
      run_shell_task(@simple_phoenix_app_path)
    end
  end

  # Checks to make sure that Gradient passes on a module that invokes `use Tesla`
  # which generates a lot of code using macros.
  describe "use Tesla" do
    @tag timeout: 120_000
    test "Gradient run is successful" do
      # run_shell_task asserts that the task had an exit code of 0, ensuring
      # there were no errors
      run_shell_task(@use_tesla_app_path)
    end
  end

  # Run the task in the current process. Useful for running on a single file.
  # def run_task(args), do: capture_io(fn -> Mix.Tasks.Gradient.run(args) end)
  def run_task(args) do
    capture_io(fn ->
      capture_io(:stderr, fn ->
        Mix.Tasks.Gradient.run(args)
      end)
    end)
  end

  # cd into a directory, run `mix deps.get`, and cd back to the previous cwd.
  # Run in setup_all so it happens once on each folder that `run_shell_task`
  # will be run on.
  defp mix_deps_get(dir) do
    previous_cwd = File.cwd!()

    try do
      # cd to umbrella app dir
      File.cd!(dir)

      # Get deps
      {_, 0} = System.cmd("mix", ["deps.get"])
    after
      File.cd!(previous_cwd)
    end
  end

  # Run the task in a new process, via the shell. Useful for running on an entire project.
  def run_shell_task(dir, args \\ []) do
    previous_cwd = File.cwd!()

    try do
      # cd to the specified dir
      File.cd!(dir)

      # mix clean first
      assert {_, 0} = System.cmd("mix", ["clean"])

      # Run the task
      {output, exit_code} = System.cmd("mix", ["gradient"] ++ args)
      # Assert the task ran successfully
      assert exit_code == 0, output

      output
    after
      File.cd!(previous_cwd)
    end
  end

  def test_opts(opts), do: ["--no-compile", "--no-deps"] ++ opts
end
