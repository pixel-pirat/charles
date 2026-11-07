import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :viso_backend, VisoBackend.Repo,
  ssl: true,
  prepare: :unnamed,
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :viso_backend, VisoBackendWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "olNyPNsC8ZkM16bRZ4PWDmu6jCL7KP2qAm9zF926U6FtJ/mU0I4R4l3G/5g0uY4z",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# ExUnit's assert_receive/assert_push/assert_reply/assert_broadcast all
# default to a 100ms timeout. Neon is a remote, pooled database —
# queries routinely take a few hundred ms from this environment, so
# any assertion downstream of a DB write needs more room than that.
config :ex_unit, assert_receive_timeout: 2_000

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Sort query params output of verified routes for robust url comparisons
config :phoenix,
  sort_verified_routes_query_params: true

# Reuses the same (gitignored) Neon dev database as config/dev.exs —
# Ecto's SQL Sandbox wraps each test in a transaction that's rolled
# back afterward, so this never leaves real data behind. Must be the
# last config import for the same reason as in dev.exs.
import_config "dev.secret.exs"
