# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# Configures the endpoint
config :paymail, PaymailWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: PaymailWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Paymail.PubSub,
  live_view: [signing_salt: "P6vuZEY4"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :block_keys, :ec_module, :libsecp256k1

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
