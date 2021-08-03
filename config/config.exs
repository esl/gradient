import Config

config :logger,
  backends: [:console],
  compile_time_purge_matching: [
    [level_lower_than: :warn]
  ]

config :logger, :console, format: "[$level] $message\n"
