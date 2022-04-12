defmodule LenraWeb.ApplicationRunnerAdapter do
  @moduledoc """
  ApplicationRunnerAdapter for LenraWeb
  Defining functions to communicate with OpenFaaS and get/save data to datastores
  """
  @behaviour ApplicationRunner.AdapterBehavior

  alias ApplicationRunner.{Data, EnvState, SessionState}
  alias Lenra.{DataServices, OpenfaasServices, User}
  require Logger

  # @impl true
  # def run_listener(
  #       %EnvState{
  #         env_id: env_id,
  #         assigns: %{
  #           environment: environment,
  #           application: application
  #         }
  #       },
  #       action,
  #       props,
  #       event
  #     ) do
  #   Logger.info("Run env listener for action #{action}")

  #   OpenfaasServices.run_env_listeners(application, environment, action, props, event, env_id)
  # end

  @impl true
  def run_listener(
        %SessionState{
          session_id: session_id,
          assigns: %{
            environment: environment,
            application: application
          }
        },
        action,
        props,
        event
      ) do
    Logger.info("Run session listener for action #{action}")

    OpenfaasServices.run_session_listeners(application, environment, action, props, event, session_id)
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
        env_id: env_id,
        assigns: %{
          user: %User{} = user
        }
      }) do
    case DataServices.get_old_data(user.id, env_id) do
      nil -> {:ok, %{}}
      %Data{} = data -> {:ok, data}
    end
  end

  @impl true
  def save_data(
        %SessionState{
          env_id: env_id,
          assigns: %{
            user: %User{} = user
          }
        },
        data
      ) do
    # TODO: change this line when data request avalaible
    case DataServices.upsert_data(user.id, env_id, %{"datastore" => "UserDatas", "data" => data}) do
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

  def on_ui_changed(session_state, message) do
    raise "Error, not maching on_ui_changed/2 #{inspect(session_state)}, #{inspect(message)}"
  end
end
