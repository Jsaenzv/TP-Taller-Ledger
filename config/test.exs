import Config

config :ledger, Ledger.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  port: 5432,
  database: "ledger_test",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10
