defmodule Paymail.Script do
  @op_dup 0x76
  @op_hash160 0xA9
  @op_equalverify 0x88
  @op_checksig 0xAC
  @op_equal 0x87

  @p2pkh_script_length 0x14
  @p2sh_script_length 0x14

  @doc """
  The `p2shwpkh` is a special case of `p2sh`, it's impossible to know whether
  an `p2sh` address has `p2shwpkh` template. As we don't use other type
  `p2sh`, just name it `p2shwpkh`.
  """
  def script_pubkey_type(
        <<@op_hash160, @p2sh_script_length, hash160::binary-size(20), @op_equal>>
      ) do
    {:p2shwpkh, hash160}
  end

  def script_pubkey_type(
        <<@op_dup, @op_hash160, @p2pkh_script_length, hash160::binary-size(20), @op_equalverify,
          @op_checksig>>
      ) do
    {:p2pkh, hash160}
  end

  def script_pubkey_type(<<0x00, 0x14>> <> hash160) do
    {:p2wpkh, hash160}
  end

  def script_pubkey_type(<<0, 32>> <> hash256) do
    {:p2wsh, hash256}
  end

  def from_script_pubkey(sp, is_testnet) do
    {type, hash160} = script_pubkey_type(sp)
    do_make_address(hash160, type, is_testnet)
  end

  defp do_make_address(hash160, type, is_testnet) do
    case type do
      :p2pkh ->
        hash160
        |> Base58Check.encode58check(:p2pkh, if(is_testnet, do: :test, else: :main))

      :p2wpkh ->
        hash160
        |> (fn x ->
              SegwitAddr.encode(
                if(is_testnet, do: "tb", else: "bc"),
                0,
                :erlang.binary_to_list(x)
              )
            end).()

      :p2shwpkh ->
        hash160
        |> Base58Check.encode58check(:p2sh, if(is_testnet, do: :test, else: :main))
    end
  end
end
