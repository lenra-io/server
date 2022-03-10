defmodule LenraWeb.CguController do
  use LenraWeb, :controller

  use LenraWeb.Policy,
    module: LenraWeb.CguController.Policy

  alias Lenra.{CguServices, LenraApplicationServices}

  defp get_app_and_allow(conn, %{"app_id" => app_id_str}) do
    with {app_id, _} <- Integer.parse(app_id_str),
         {:ok, app} <- LenraApplicationServices.fetch(app_id),
         :ok <- allow(conn, app) do
      {:ok, app}
    end
  end

  def create(conn, params) do
    with {:ok, %{latest_cgu: cgu}} <- CguServices.get_latest_cgu() do
      conn
      |> assign_data(:latest_cgu, cgu)
      |> reply
    end
  end
end
