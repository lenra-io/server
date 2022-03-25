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

  alias ApplicationRunner.Datastore

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
    Repo.all(from(a in LenraApplication, where: a.creator_id == ^user_id))
  end

  def fetch(app_id) do
    Repo.fetch(LenraApplication, app_id)
  end

  def fetch_by(clauses, error \\ {:error, :error_404}) do
    Repo.fetch_by(LenraApplication, clauses, error)
  end

  def create(user_id, params) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:inserted_application, LenraApplication.new(user_id, params))
    |> Ecto.Multi.insert(:inserted_main_env, fn %{inserted_application: app} ->
      Environment.new(app.id, user_id, nil, %{name: "live", is_ephemeral: false, is_public: false})
    end)
    |> Ecto.Multi.insert(:inserted_datastore, fn %{inserted_main_env: env} ->
      Datastore.new(env.id, %{"name" => "UserDatas"})
    end)
    |> Ecto.Multi.insert(:application_main_env, fn %{
                                                     inserted_application: app,
                                                     inserted_main_env: env
                                                   } ->
      ApplicationMainEnv.new(app.id, env.id)
    end)
    |> Repo.transaction()
  end

  def delete(app) do
    Ecto.Multi.new()
    |> Ecto.Multi.delete(:deleted_application, app)
    |> Repo.transaction()
  end
end
