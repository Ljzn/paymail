defmodule Paymail.Req do
  def get(url, headers \\ [], opts \\ []) do
    {:ok,
     {
       {_, status, _},
       _,
       data
     }} = :httpc.request(:get, {url, headers}, [{:ssl, ssl_option()}], opts)

    {:ok,
     %{
       status: status,
       body: IO.iodata_to_binary(data)
     }}
  end

  def get!(url, headers \\ [], opts \\ []) do
    {:ok, resp} = get(url, headers, opts)
    resp
  end

  def post(url, body, headers \\ [], opts \\ []) do
    {:ok,
     {
       {_, status, _},
       _,
       data
     }} =
      :httpc.request(
        :post,
        {url, headers, 'application/json', body},
        [{:ssl, ssl_option()}],
        opts
      )

    {:ok,
     %{
       status: status,
       body: IO.iodata_to_binary(data)
     }}
  end

  def post!(url, body, headers \\ [], opts \\ []) do
    {:ok, resp} = post(url, body, headers, opts)
    resp
  end

  def ssl_option(),
    do: [
      {:versions, [:"tlsv1.2"]},
      {:verify, :verify_peer},
      {:cacerts, :certifi.cacerts()},
      {:customize_hostname_check,
       [{:match_fun, :public_key.pkix_verify_hostname_match_fun(:https)}]}
    ]
end
