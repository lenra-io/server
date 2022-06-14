defmodule LenraWeb.Guardian do
  @moduledoc """
    LenraWeb.Guardian handle the callback operations to generate and verify the token.
  """

  use Guardian, otp_app: :lenra_web

  alias Lenra.UserServices
  require Logger

  defmacro __using__(opts) do
    quote do
      def subject_for_token(user, _claims) do
        {:ok, to_string(user.id)}
      end

      def resource_from_claims(%{"sub" => id_string}) do
        case UserServices.get(id_string) do
          nil ->
            raise "Cannot parse subject from claims"

          user ->
            {:ok, user}
        end
      end

      def resource_from_claims(_claims), do: {:error, [:unhandled_resource_type]}

      def after_encode_and_sign(resource, claims, token, _options) do
        with {:ok, _} <- Guardian.DB.after_encode_and_sign(resource, claims["typ"], claims, token) do
          {:ok, token}
        end
      end

      def on_verify(claims, token, _options) do
        with {:ok, _} <- Guardian.DB.on_verify(claims, token) do
          {:ok, claims}
        end
      end

      def on_refresh({old_token, old_claims}, {new_token, new_claims}, _options) do
        with {:ok, _, _} <- Guardian.DB.on_refresh({old_token, old_claims}, {new_token, new_claims}) do
          {:ok, {old_token, old_claims}, {new_token, new_claims}}
        end
      end

      def on_revoke(claims, token, _options) do
        with {:ok, _} <- Guardian.DB.on_revoke(claims, token) do
          {:ok, claims}
        end
      end
    end
  end
end
