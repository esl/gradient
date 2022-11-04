defmodule SimplePhoenixApp.Repo do
  use Ecto.Repo,
    otp_app: :simple_phoenix_app,
    adapter: Ecto.Adapters.Postgres
end
