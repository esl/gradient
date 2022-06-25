defmodule Gradient.MixProject do
  use Mix.Project

  def project do
    [
      app: :gradient,
      version: "0.1.0",
      elixir: "~> 1.11",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      dialyzer: [plt_add_apps: [:mix]],
      escript: escript()
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :syntax_tools]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  def deps do
    [
      {:gradualizer, github: "josefs/Gradualizer", ref: "ba5481c", manager: :rebar3},
      # {:gradualizer, path: "../Gradualizer/", manager: :rebar3},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.28.4", only: [:dev], runtime: false}
    ]
  end

  def aliases do
    []
  end

  def escript() do
    [main_module: Gradient.CLI]
  end
end
