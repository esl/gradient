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
      {:gradient, path: "../../"},
      {:dialyxir, "~> 1.1", only: [:dev, :test], runtime: false}
    ]
  end

  defp dialyzer do
    [
      plt_add_deps: :app_tree,
      # ignore_warnings: "dialyzer.ignore-warnings",
      flags: ~w(
        error_handling
        race_conditions
        unmatched_returns
        underspecs
      )a
    ]
  end
end
