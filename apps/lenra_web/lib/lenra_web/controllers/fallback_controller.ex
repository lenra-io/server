defmodule LenraWeb.FallbackController do
  use LenraWeb, :controller

  def call(conn, {:error, reason}) do
    conn
    |> assign_error(reason)
    |> reply
  end

  def call(conn, {:error, _, reason, _}) do
    conn
    |> assign_error(reason)
    |> reply
  end
end
