defmodule Paymail.Client do
  alias Paymail.Req
  alias Paymail.Script

  @brfc_receive_tx "5f1323cddf31"

  def get_capabilities(url) do
    host = host_discovery(url)
    url = "https://#{host}"

    body =
      case Req.get!(Path.join(url, "/.well-known/bsvalias")) do
        %{body: body, status: 200} ->
          body

        # handle redirect
        %{status: 302, headers: headers} ->
          loc = :proplists.get_value("location", headers)
          %{body: body, status: 200} = Req.get!(loc)
          body
      end

    %{"bsvalias" => "1.0", "capabilities" => caps} = Jason.decode!(body)
    caps
  end

  # we use the cloudflare DNS server to auto validate DNSSEC
  def host_discovery("https://" <> _ = url) do
    %{host: host} = URI.parse(url)

    with %{body: data, status: 200} <-
           Req.get!(
             "https://cloudflare-dns.com/dns-query?name=_bsvalias._tcp.#{host}&type=SRV",
             [{"accept", "application/dns-json"}]
           ),
         {:ok, %{"Status" => 0, "AD" => true, "Answer" => records}} <- Jason.decode(data),
         [[_, _, "443", target] | _] <-
           Enum.map(records, fn %{"data" => x} -> String.split(x, " ") end) do
      target
    else
      _ ->
        host
    end
  end

  @doc """
  Get the bitcoin address of a paymail.

  ## Examples:

    iex> get_address("390@moneybutton.com")
    "1B7spYKxzGFUxrQbJ2QyvmS7d8We1kCVi3"
  """
  def get_address(paymail) do
    [_id, host] = String.split(paymail, "@")
    caps = get_capabilities("https://" <> host)

    url = caps["paymentDestination"]

    %{body: body, status: 200} =
      Req.post!(
        String.replace(url, "{alias}@{domain.tld}", paymail),
        %{
          "senderHandle" => paymail,
          "dt" => DateTime.utc_now() |> DateTime.to_string()
        }
        |> Jason.encode!(),
        [{"content-type", "application/json"}]
      )

    %{"output" => hex} = Jason.decode!(body)
    pubkeyhash = Base.decode16!(hex, case: :mixed)

    # validate pubkeyhash
    {:p2pkh, _} = Script.script_pubkey_type(pubkeyhash)

    Script.from_script_pubkey(pubkeyhash, false)
  end

  def send_tx(paymail, raw) do
    [_id, host] = String.split(paymail, "@")
    caps = get_capabilities("https://" <> host)

    url = caps[@brfc_receive_tx]

    Req.post!(
      String.replace(url, "{alias}@{domain.tld}", paymail),
      Jason.encode!(%{
        hex: raw,
        metadata: %{},
        reference: DateTime.utc_now() |> DateTime.to_string()
      }),
      [{"content-type", "application/json"}]
    )
  end
end
