defmodule PaymailWeb.PageController do
  use PaymailWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
