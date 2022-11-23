defmodule AppB.MixProject do
  use Mix.Project
  def project do
    [
      app: :app_b,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      
    ]
  end
  
    defp deps, do: [{:app_a, in_umbrella: true}]
  
end
