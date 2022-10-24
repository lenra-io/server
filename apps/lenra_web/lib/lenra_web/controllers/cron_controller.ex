defmodule LenraWeb.CronController do
  use LenraWeb, :controller

  alias ApplicationRunner.Crons.CronServices

  def create(conn, %{"env_id" => env_id} = params) do
    {env_id_int, ""} = Integer.parse(env_id)
    with {:ok, cron} <-
           env_id_int
           |> CronServices.create(params) do
      conn
      |> reply(cron)
    end
  end

  def get(conn, %{"id" => cron_id} = _params) do
    with {:ok, cron} <-
           CronServices.get(cron_id) do
      conn
      |> reply(cron)
    end
  end

  def all(conn, %{"user_id" => user_id}) do
    with {:ok, crons} <-
           Guardian.Plug.current_resource(conn)
           |> CronServices.all(user_id) do
      conn
      |> reply(crons)
    end
  end

  def all(conn, _params) do
    with {:ok, crons} <-
           CronServices.all() do
      conn
      |> reply(crons)
    end
  end

  def update(conn, %{"id" => cron_id} = params) do
    with {:ok, cron} <- CronServices.get(cron_id),
         {:ok, updated_cron} <- CronServices.update(cron, params) do
      conn
      |> reply(updated_cron)
    end
  end
end
