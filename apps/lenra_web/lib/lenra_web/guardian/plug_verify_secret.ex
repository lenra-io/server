defmodule Lenra.Plug.VerifySecret do
  @moduledoc """
  A plug used to verify if a secret header is set.
  The secret must be passed by the caller.
  The secret name can be set by the caller. default : "secret_token"
  """

  import Plug.Conn
  import Phoenix.Controller

  def init(opts \\ []), do: opts

  def call(conn, _opts) do
    secret = Application.fetch_env!(:lenra, :runner_secret)

    case conn.query_params do
      %{"secret" => ^secret} ->
        conn

      e ->
        IO.puts(inspect(e))
        error(conn)
    end
  end

  defp error(conn) do
    conn
    |> put_view(LenraWeb.ErrorView)
    |> put_status(401)
    |> render("401.json", message: "Unauthorized")
    |> halt
  end
end
