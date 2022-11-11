defmodule PaymailWeb.ApiControllerTest do
  use PaymailWeb.ConnCase, async: false

  setup do
    System.put_env("PAYMAIL_HOST", "localhost")

    System.put_env(
      "PAYMAIL_XPUB",
      "xpub6DQT2KPkj9iTA9zRwKbRuUwZypruLY3MYT77jXgn1xwpXQr6f86hBCkjErQaYDyhu5X6s5hmpvWkun3vyMsX5kZjZubAQrcFd4ZTPSCKqZ8"
    )
  end

  test "GET /.well-known/bsvalias", %{conn: conn} do
    conn = get(conn, "/.well-known/bsvalias")
    body = json_response(conn, 200)

    assert body["capabilities"]
  end

  test "POST /api/v1/bsvalias/address/:paymail", %{conn: conn} do
    conn = post(conn, "/api/v1/bsvalias/address/98@localhost", %{})
    body = json_response(conn, 200)

    assert body["output"] == "76a91425f01de28473a70720cfd1ee7b5cf68ceb36020288ac"
  end

  test "POST /api/v1/bsvalias/address/:paymail with wrong paymail", %{conn: conn} do
    conn = post(conn, "/api/v1/bsvalias/address/988@localhost", %{})
    body = json_response(conn, 404)

    assert body["error"]

    conn = post(conn, "/api/v1/bsvalias/address/98@github.com", %{})
    body = json_response(conn, 404)

    assert body["error"]
  end

  test "POST /api/v1/bsvalias/receive-rawtx/:paymail", %{conn: conn} do
    Paymail.DB.clear()

    conn =
      post(conn, "/api/v1/bsvalias/receive-rawtx/98@localhost", %{
        hex:
          "0100000001b4503f255a4653cf7e1c113b3d098c1542d6ebffb5534a82169bc32cf53f5979010000006a47304402204204971959855a2e158bcd78ee5a67357b8424b59d56997eadb00661e4d50142022051babf6a4273eb0a346ffdbf3e97aabddebb0a140de44eaea6ef29df6bd8a3b94121030ae32e934b34965c785ff68dbadb6ef39692b0c3a94546e4d1d9ebeb6b6b282cffffffff02530e0000000000001976a91425f01de28473a70720cfd1ee7b5cf68ceb36020288ac5c110100000000001976a914f3d95dacf2e1ace04e314ee135ace20be39762c188ac00000000",
        metadata: %{},
        reference: DateTime.utc_now() |> DateTime.to_string()
      })

    body = json_response(conn, 200)
    assert body["txid"] == "ddc76b3f5aeda0e7eaec84c499a8cd8ed53fb0b71a14f05a358aeac163c86b25"
  end

  test "GET /tx", %{conn: conn} do
    st = DateTime.utc_now() |> DateTime.add(-100) |> DateTime.to_iso8601()
    et = DateTime.utc_now() |> DateTime.add(100) |> DateTime.to_iso8601()
    conn = get(conn, "/tx?start_timestamp=#{st}&end_timestamp=#{et}")

    body = json_response(conn, 200)
    # may need change if we inserted multi txs before
    assert length(body["data"]) == 1
  end
end
