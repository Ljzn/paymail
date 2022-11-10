defmodule PaymailWeb.Router do
  use PaymailWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PaymailWeb do
    pipe_through :api

    get "/tx", ApiController, :deposits
  end

  # Other scopes may use custom stacks.
  scope "/.well-known", PaymailWeb do
    pipe_through :api

    get "/bsvalias", ApiController, :bsvalias
  end

  scope "/api/v1/bsvalias", PaymailWeb do
    pipe_through :api

    get "/address/:paymail", ApiController, :address
    post "/receive-rawtx/:paymail", ApiController, :receive_rawtx
  end
end
