import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :paymail, PaymailWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "yClm1VmQSc0ZnYk3WQCKC2QWIXJA/cdullk3KZA10+HTLT6zasGffqA5Qg+eKoYH",
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
