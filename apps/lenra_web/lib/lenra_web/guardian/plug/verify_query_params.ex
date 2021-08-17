if Code.ensure_loaded?(Plug) do
  defmodule Lenra.Guardian.Plug.VerifyQueryParams do
    @moduledoc """
      Looks for and validates a token found in the `token` query parameter.
    """
    alias Guardian.Plug.Pipeline

    import Plug.Conn

    @behaviour Plug

    @impl Plug
    def init(default), do: default

    @impl Plug
    @spec call(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
    def call(conn, opts) do
      with nil <- Guardian.Plug.current_token(conn, opts),
           {:ok, token} <- fetch_token_from_query_params(conn),
           module <- Pipeline.fetch_module!(conn, opts),
           claims_to_check <- Keyword.get(opts, :claims, %{}),
           key <- storage_key(conn, opts),
           {:ok, claims} <- Guardian.decode_and_verify(module, token, claims_to_check, opts) do
        conn
        |> Guardian.Plug.put_current_token(token, key: key)
        |> Guardian.Plug.put_current_claims(claims, key: key)
      else
        :no_token_found ->
          conn

        {:error, reason} ->
          conn
          |> Pipeline.fetch_error_handler!(opts)
          |> apply(:auth_error, [conn, {:invalid_token, reason}, opts])
          |> Guardian.Plug.maybe_halt(opts)

        _ ->
          conn
      end
    end

    defp fetch_token_from_query_params(conn) do
      conn = fetch_query_params(conn)

      case conn.params["token"] do
        nil -> :no_token_found
        token -> {:ok, token}
      end
    end

    @spec storage_key(Plug.Conn.t(), Keyword.t()) :: String.t()
    defp storage_key(conn, opts), do: Pipeline.fetch_key(conn, opts)
  end
end
