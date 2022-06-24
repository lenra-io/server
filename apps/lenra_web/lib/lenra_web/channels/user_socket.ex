defmodule LenraWeb.UserSocket do
  use ApplicationRunner.UserSocket, channel: LenraWeb.AppChannel

  defp resource_from_token(token) do
    case LenraWeb.Guardian.resource_from_token(token) do
      {:ok, user, _claims} ->
        {:ok, user.id}

      _error ->
        :error
    end
  end
end
