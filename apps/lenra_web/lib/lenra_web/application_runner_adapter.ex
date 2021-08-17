defmodule LenraWeb.ApplicationRunnerAdapter do
  @moduledoc """
  ApplicationRunnerAdapter for LenraWeb
  Defining functions to communicate with OpenFaaS and get/save data to datastores
  """
  @behaviour ApplicationRunner.AdapterBehavior

  alias Lenra.{LenraApplicationServices, DatastoreServices, Openfaas}

  @impl ApplicationRunner.AdapterBehavior
  def run_action(action) do
    Openfaas.run_action(action)
  end

  @impl ApplicationRunner.AdapterBehavior
  def get_data(action) do
    with {:ok, application} <-
           LenraApplicationServices.fetch_by([service_name: action.app_name], {:error, :no_such_application}) do
      DatastoreServices.assign_old_data(action, application.id)
    end
  end

  @impl ApplicationRunner.AdapterBehavior
  def save_data(action, data) do
    with {:ok, application} <-
           LenraApplicationServices.fetch_by([service_name: action.app_name], {:error, :no_such_application}) do
      DatastoreServices.upsert_data(action.user_id, application.id, data)
    end
  end
end
