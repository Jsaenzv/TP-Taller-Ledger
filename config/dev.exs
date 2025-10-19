import Config

config :ledger, Ledger.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  port: 5432,
  database: "ledger",
  show_sensitive_data_on_connection_error: true,
  stacktrace: true,
  pool_size: 10
