defmodule TypedGenServer.MixProject do
  use Mix.Project

  def project do
    [
      app: :typed_gen_server,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: dialyzer()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {TypedGenServer.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:dialyxir, "~> 1.1", only: [:dev, :test], runtime: false},
      {:gradualizer,
       github: "erszcz/Gradualizer", ref: "typed-gen-server", manager: :rebar3, override: true},
      {:gradualizer_ex, github: "erszcz/gradualizer-ex", branch: "rs/wip"}
    ]
  end

  defp dialyzer do
    [
      plt_add_deps: :app_tree,
      #ignore_warnings: "dialyzer.ignore-warnings",
      flags: ~w(
        error_handling
        race_conditions
        unmatched_returns
        underspecs
      )a
    ]
  end

end
