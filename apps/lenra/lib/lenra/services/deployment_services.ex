defmodule Lenra.DeploymentServices do
  @moduledoc """
    The service that manages the different possible actions on a deployment.
  """
  require Logger

  alias Lenra.{Repo, Deployment, Build, BuildServices, EnvironmentServices, Openfaas}

  def get(deployment_id) do
    Repo.get(Deployment, deployment_id)
  end

  def get_by(clauses) do
    Repo.get_by(Deployment, clauses)
  end

  def deploy_in_main_env(%Build{} = build) do
    with loaded_build <- Repo.preload(build, :application),
         loaded_app <- Repo.preload(loaded_build.application, :main_env) do
      create(loaded_app.main_env.environment_id, build.id, build.creator_id)
    end
  end

  def create(environment_id, build_id, publisher_id, params \\ %{}) do
    build =
      BuildServices.get(build_id)
      |> Repo.preload(:application)

    env = EnvironmentServices.get(environment_id)

    # a faire: back previous deployed build, check if it's present in another env and if not, remove it from OpenFaaS

    Ecto.Multi.new()
    |> Ecto.Multi.update(:updated_env, Ecto.Changeset.change(env, deployed_build_id: build.id))
    |> Ecto.Multi.insert(
      :inserted_deployment,
      Deployment.new(build.application.id, environment_id, build_id, publisher_id, params)
    )
    |> Ecto.Multi.run(:openfaas_deploy, fn _repo, _ ->
      # a faire: check if this build is already deployed on another env
      Openfaas.deploy_app(build.application.service_name, build.build_number)
    end)
    |> Repo.transaction()
  end

  def image_name(service_name, build_number) do
    lenra_env = Application.fetch_env!(:lenra, :lenra_env)
    faas_registry = Application.fetch_env!(:lenra, :faas_registry)

    "#{faas_registry}/#{lenra_env}/#{service_name}:#{build_number}"
  end

  def delete(deployment) do
    Ecto.Multi.new()
    |> Ecto.Multi.delete(:deleted_deployment, deployment)
  end
end
