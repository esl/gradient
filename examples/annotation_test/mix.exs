defmodule AnnotationTest.MixProject do
  use Mix.Project

  def project do
    [
      app: :annotation_test,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:gradient_macros, github: "esl/gradient_macros", ref: "3bce214", runtime: false},
      {:gradient, path: "../../", runtime: false}
    ]
  end
end
