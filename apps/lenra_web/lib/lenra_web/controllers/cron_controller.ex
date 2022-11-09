defmodule LenraWeb.CronController do
  use LenraWeb, :controller

  alias ApplicationRunner.Crons.CronServices

  def create(conn, %{"env_id" => env_id} = params) do
    {env_id_int, ""} = Integer.parse(env_id)

    app =
      Lenra.Repo.get(Lenra.Apps.App, Map.get(params, "app_id"))
      |> Lenra.Repo.preload(main_env: [environment: [:deployed_build]])

    case app.main_env.environment.deployed_build do
      nil ->
        Lenra.Errors.BusinessError.application_not_built_tuple()

      _ ->
        with {:ok, cron} <-
               env_id_int
               |> CronServices.create(
                 Map.merge(
                   params,
                   %{
                     "app_name" => app.name,
                     "function_name" =>
                       Lenra.OpenfaasServices.get_function_name(
                         app.service_name,
                         app.main_env.environment.deployed_build.build_number
                       )
                   }
                 )
               ) do
          conn
          |> reply(cron)
        end
    end
  end

  def get(conn, %{"id" => cron_id} = _params) do
    with {:ok, cron} <-
           CronServices.get(cron_id) do
      conn
      |> reply(cron)
    end
  end

  def all(conn, %{"env_id" => env_id, "user_id" => user_id} = _params) do
    conn
    |> reply(CronServices.all(env_id, user_id))
  end

  def all(conn, %{"env_id" => env_id} = _params) do
    conn
    |> reply(CronServices.all(env_id))
  end

  def update(conn, %{"id" => cron_id} = params) do
    with {:ok, cron} <- CronServices.get(cron_id),
         {:ok, updated_cron} <- CronServices.update(cron, params) do
      conn
      |> reply(updated_cron)
    end
  end
end
