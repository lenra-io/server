defmodule Crypto do
  @moduledoc """
    Crypto is a utility module for all crypto realated utilities
  """
  def hash(tuple) do
    :crypto.hash(:sha256, :erlang.term_to_binary(tuple))
    |> Base.encode64()
  end
end
