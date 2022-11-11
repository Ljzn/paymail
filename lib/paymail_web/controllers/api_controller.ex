defmodule PaymailWeb.ApiController do
  use PaymailWeb, :controller
  alias Paymail.DB

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
    with {:ok, i} <- validate_paymail(paymail) do
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

  defp validate_paymail(paymail) do
    host = System.fetch_env!("PAYMAIL_HOST")

    with [index, ^host] <- String.split(paymail, "@"),
         i when i > 0 <- String.to_integer(index),
         1 <- rem(i, @bsv_paymail_index_step) do
      {:ok, i}
    else
      err ->
        {:error, err}
    end
  end

  def receive_rawtx(conn, %{"paymail" => paymail, "hex" => hex} = _params) do
    with {:ok, _i} <- validate_paymail(paymail) do
      ts = DateTime.utc_now() |> DateTime.to_unix()
      txid = hex_to_txid(hex)
      :ok = save({ts, txid}, {paymail, hex})

      conn
      |> json(%{
        txid: txid
      })
    else
      err ->
        conn
        |> put_status(404)
        |> json(%{"error" => "The paymail #{paymail} is invalid, reason: #{inspect(err)}"})
    end
  end

  def deposits(conn, %{"start_timestamp" => st, "end_timestamp" => et}) do
    st = to_unix(st)
    et = to_unix(et)

    data =
      DB.select(min_key: {st, ""}, max_key: {et, ""})
      |> Enum.map(fn {{ts, _txid}, {paymail, hex}} ->
        %{
          "hex" => hex,
          "paymail" => paymail,
          "created_at" => DateTime.from_unix!(ts) |> DateTime.to_iso8601()
        }
      end)

    conn
    |> json(%{
      data: data
    })
  end

  defp save(key, value) do
    DB.put(key, value)
  end

  defp sha256(data), do: :crypto.hash(:sha256, data)
  defp ripemd160(data), do: :crypto.hash(:ripemd160, data)
  defp hash160(data), do: data |> sha256() |> ripemd160()
  defp double_sha256(data), do: data |> sha256 |> sha256

  defp derive_pubkey(index) do
    xpub = System.fetch_env!("PAYMAIL_XPUB")

    %{key: pub} =
      BlockKeys.CKD.derive(xpub, "M/0/#{index}") |> BlockKeys.Encoding.decode_extended_key()

    {:ok, full_pub} = :libsecp256k1.ec_pubkey_decompress(pub)
    full_pub
  end

  defp hex_to_txid(raw) do
    raw
    |> Base.decode16!(case: :mixed)
    |> double_sha256()
    |> reverse()
    |> Base.encode16(case: :lower)
  end

  defp reverse(binary) when is_binary(binary), do: do_reverse(binary, <<>>)
  defp do_reverse(<<>>, acc), do: acc
  defp do_reverse(<<x::binary-size(1), bin::binary>>, acc), do: do_reverse(bin, x <> acc)

  defp to_unix(t) when is_binary(t) do
    {:ok, dt, 0} = DateTime.from_iso8601(t)
    DateTime.to_unix(dt)
  end
end
