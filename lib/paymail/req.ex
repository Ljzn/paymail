defmodule Paymail.Req do
  def get(url, headers \\ [], opts \\ []) do
    headers = bins_to_lists(headers)

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
    headers = bins_to_lists(headers)

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

  defp bins_to_lists(headers) do
    Enum.map(headers, fn {k, v} ->
      {:erlang.binary_to_list(k), :erlang.binary_to_list(v)}
    end)
  end
end
