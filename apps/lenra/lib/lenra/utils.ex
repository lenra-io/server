defmodule Lenra.Utils do
  @moduledoc """
    This module handle all utils for a user.
    - Hash a file
  """
  alias Lenra.Errors.TechnicalError

  def hash_file(path, algo) do
    case File.exists?(path) do
      true ->
        path
        |> File.stream!([], 2048)
        |> Enum.reduce(:crypto.hash_init(algo), &:crypto.hash_update(&2, &1))
        |> :crypto.hash_final()
        |> Base.encode16()

      false ->
        TechnicalError.file_not_found_tuple()
    end
  end
end
