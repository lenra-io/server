defmodule LenraWeb.ApplicationRunnerAdapter do
  @moduledoc """
  ApplicationRunnerAdapter for LenraWeb
  Defining functions to communicate with OpenFaaS and get/save data to datastores
  """
  @behaviour ApplicationRunner.AdapterBehavior

  alias ApplicationRunner.{EnvState, SessionState}
  alias Lenra.{Datastore, DatastoreServices, LenraApplication, OpenfaasServices, User}
  require Logger

  @impl true
  def run_listener(
        %EnvState{
          assigns: %{
            environment: environment,
            application: application
          }
        },
        action,
        data,
        props,
        event
      ) do
    Logger.info("Run listener for action #{action}")
    OpenfaasServices.run_listener(application, environment, action, data, props, event)
  end

  @impl true
  def get_widget(
        %EnvState{
          assigns: %{
            environment: environment,
            application: application
          }
        },
        widget_name,
        data,
        props
      ) do
    Logger.info("Get widget #{widget_name}")
    OpenfaasServices.fetch_widget(application, environment, widget_name, data, props)
  end

  @impl true
  def get_manifest(%EnvState{
        assigns: %{
          environment: environment,
          application: application
        }
      }) do
    Logger.info("Get manifest")

    OpenfaasServices.fetch_manifest(application, environment)
  end

  def get_manifest(env) do
    raise "Woops, env not good #{inspect(env)}"
  end

  @impl true
  def get_data(%SessionState{
        assigns: %{
          application: %LenraApplication{} = application,
          user: %User{} = user
        }
      }) do
    case DatastoreServices.get_old_data(user.id, application.id) do
      nil -> {:ok, %{}}
      %Datastore{} = datastore -> {:ok, datastore.data}
    end
  end

  @impl true
  def save_data(
        %SessionState{
          assigns: %{
            application: %LenraApplication{} = application,
            user: %User{} = user
          }
        },
        data
      ) do
    case DatastoreServices.upsert_data(user.id, application.id, data) do
      {:ok, _} -> :ok
      {:error, _} -> {:error, :cannot_save_data}
    end
  end

  @impl true
  def on_ui_changed(
        %SessionState{
          assigns: %{
            socket_pid: socket_pid
          }
        },
        {atom, ui_or_patches}
      ) do
    send(socket_pid, {:send, atom, ui_or_patches})
  end
end
