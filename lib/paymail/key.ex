defmodule Paymail.Key do
  # TODO move to config
  @xpub "xpub6DAicCrG3u4D7XEYBnGUSr2uA7mW9MjFAm5AznUkXDuLrVaqAFPRhnMhEN8WKSGLCkhJnXNtPbGoJYP8rds33Yqno68VRchscQ4vNwchHir"
  # @path "M/44'/0'/0'"

  def get_address(index) do
    BlockKeys.Bitcoin.address(@xpub, "M/#{index}/0")
  end
end
