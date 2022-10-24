defmodule PaymailWeb.ApiController do
  use PaymailWeb, :controller

  def bsvalias(conn, _params) do
    render(conn, "index.html")
  end
end
