defmodule SimpleUmbrellaApp.MixProject do
  use Mix.Project
  def project do
    [
      apps_path: "apps",
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      
        gradient: [
          
            enabled: true,
          
          
        ]
      
    ]
  end
  defp deps do
    [{:gradient, path: "../../", override: true}]
  end
end
