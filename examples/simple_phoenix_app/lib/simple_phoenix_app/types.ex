# Define Ecto extension types for Postgrex

alias Ecto.Adapters.Postgres
alias Postgrex.Types

Types.define(SimplePhoenixApp.Repo.PostgresTypes, Postgres.extensions())
