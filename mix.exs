defmodule Gradient.MixProject do
  use Mix.Project

  def project do
    [
      app: :gradient,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      dialyzer: [plt_add_apps: [:mix]]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  def deps do
    [
      # {:gradualizer, path: "../Gradualizer", manager: :rebar3}
      {:gradualizer, github: "josefs/Gradualizer", ref: "master", manager: :rebar3},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false}
    ]
  end

  def aliases do
    []
  end
end
