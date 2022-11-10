defmodule PaymailWeb.ApiController do
  use PaymailWeb, :controller

  @bsv_paymail_index_step 97

  def bsvalias(conn, _params) do
    host = System.fetch_env!("PAYMAIL_HOST")

    conn
    |> json(%{
      "bsvalias" => "1.0",
      "capabilities" => %{
        "5f1323cddf31" => "https://#{host}/api/v1/bsvalias/receive-rawtx/{alias}@{domain.tld}",
        "paymentDestination" => "https://#{host}/api/v1/bsvalias/address/{alias}@{domain.tld}"
      }
    })
  end

  @op_dup 0x76
  @op_hash160 0xA9
  @op_equalverify 0x88
  @op_checksig 0xAC
  @p2pkh_script_length 0x14

  def address(conn, %{"paymail" => paymail}) do
    host = System.fetch_env!("PAYMAIL_HOST")

    with [index, ^host] <- String.split(paymail, "@"),
         i when i > 0 <- String.to_integer(index),
         1 <- rem(i, @bsv_paymail_index_step) do
      pub = derive_pubkey(i)
      hash160 = hash160(pub)

      script =
        <<@op_dup, @op_hash160, @p2pkh_script_length, hash160::binary-size(20), @op_equalverify,
          @op_checksig>>

      conn
      |> json(%{"output" => Base.encode16(script, case: :lower)})
    else
      err ->
        conn
        |> put_status(404)
        |> json(%{"error" => "The paymail #{paymail} is invalid, reason: #{inspect(err)}"})
    end
  end

  def receive_rawtx(conn, params) do
  end

  def deposits(conn, %{"start_timestamp" => st, "end_timestamp" => et}) do
    conn
    |> json(%{
      data: [
        %{
          "hex" => "",
          "paymail" => "98@localhost",
          "created_at" => DateTime.utc_now() |> to_string()
        }
      ]
    })
  end

  defp sha256(data), do: :crypto.hash(:sha256, data)
  defp ripemd160(data), do: :crypto.hash(:ripemd160, data)
  defp hash160(data), do: data |> sha256() |> ripemd160()

  defp derive_pubkey(index) do
    xpub = System.fetch_env!("PAYMAIL_XPUB")

    %{key: pub} =
      BlockKeys.CKD.derive(xpub, "M/0/#{index}") |> BlockKeys.Encoding.decode_extended_key()

    {:ok, full_pub} = :libsecp256k1.ec_pubkey_decompress(pub)
    full_pub
  end
end
