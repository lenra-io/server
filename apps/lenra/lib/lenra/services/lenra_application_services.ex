defmodule Lenra.LenraApplicationServices do
  @moduledoc """
    The service that manages possible actions on a lenra application.
  """
  import Ecto.Query

  alias Lenra.{
    ApplicationMainEnv,
    Environment,
    EnvironmentServices,
    LenraApplication,
    Repo,
    UserEnvironmentAccess
  }

  require Logger

  def all(user_id) do
    Repo.all(
      from(a in LenraApplication,
        join: m in ApplicationMainEnv,
        on: a.id == m.application_id,
        join: e in Environment,
        on: m.environment_id == e.id,
        left_join: u in UserEnvironmentAccess,
        on: e.id == u.environment_id and ^user_id == u.user_id,
        where: a.creator_id == ^user_id or e.is_public or u.user_id == ^user_id
      )
    )
  end

  def all_for_user(user_id) do
    Repo.all(
      from(a in LenraApplication,
        where: a.creator_id == ^user_id,
        select: %{
          id: a.id,
          name: a.name,
          color: a.color,
          icon: a.icon,
          service_name: a.service_name,
          creator_id: a.creator_id,
          repository: a.repository,
          repository_branch: a.repository_branch
        }
      )
    )
  end

  def fetch(app_id) do
    Repo.fetch(LenraApplication, app_id)
  end

  def fetch_by(clauses, error \\ {:error, Lenra.Errors.error_404}) do
    Repo.fetch_by(LenraApplication, clauses, error)
  end

  def create(user_id, params) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:inserted_application, LenraApplication.new(user_id, params))
    |> EnvironmentServices.create_with_app(user_id, %{name: "live", is_ephemeral: false, is_public: false})
    |> Ecto.Multi.insert(:application_main_env, fn %{
                                                     inserted_application: app,
                                                     inserted_env: env
                                                   } ->
      ApplicationMainEnv.new(app.id, env.id)
    end)
    |> Repo.transaction()
  end

  def update(app, params) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:updated_application, LenraApplication.update(app, params))
    |> Repo.transaction()
  end

  def delete(app) do
    Ecto.Multi.new()
    |> Ecto.Multi.delete(:deleted_application, app)
    |> Repo.transaction()
  end
end
