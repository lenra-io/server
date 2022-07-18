defmodule Lenra.ResourcesServices do
  @moduledoc """
    The service that manages resources of lenra applications.
  """
  alias ApplicationRunner.OpenfaasServices
  alias Lenra.{LenraApplicationServices, Repo}
  require Logger

  @doc """
  Gets the `resource` from an app.

  Returns an `Enum`.
  """
  def get(user_id, service_name, resource) do
    with {:ok, app} <- LenraApplicationServices.fetch_by(service_name: service_name, creator_id: user_id),
         loaded_app <- Repo.preload(app, main_env: [environment: [:deployed_build]]) do
      lenra_env = Application.fetch_env!(:lenra, :lenra_env)

      build_number = loaded_app.main_env.environment.deployed_build.build_number
      OpenfaasServices.get_app_resource(String.downcase("#{lenra_env}-#{service_name}-#{build_number}"), resource)
    end
  end
end
