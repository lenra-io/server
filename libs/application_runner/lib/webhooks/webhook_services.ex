defmodule ApplicationRunner.Webhooks.WebhookServices do
  @moduledoc """
    The service that manages the webhooks.
  """

  import Ecto.Query, only: [from: 2]

  alias ApplicationRunner.Errors.TechnicalError
  alias ApplicationRunner.EventHandler
  alias ApplicationRunner.Webhooks.Webhook

  @repo Application.compile_env(:application_runner, :repo)

  def create(env_id, params) do
    Webhook.new(env_id, params)
    |> @repo.insert()
  end

  def app_create(
        %{
          environment: %ApplicationRunner.Contract.Environment{id: env_id},
          user: %ApplicationRunner.Contract.User{id: user_id}
        },
        params
      ) do
    create(env_id, Map.merge(params, %{"user_id" => user_id}))
  end

  def app_create(%{environment: %ApplicationRunner.Contract.Environment{id: env_id}}, params) do
    create(env_id, params)
  end

  def get(env_id) do
    @repo.all(from(w in Webhook, where: w.environment_id == ^env_id))
  end

  def get(env_id, user_id) do
    @repo.all(from(w in Webhook, where: w.environment_id == ^env_id and w.user_id == ^user_id))
  end

  def get_by_uuid(uuid) do
    @repo.get(Webhook, uuid)
  end

  def trigger(webhook_uuid, payload) do
    case @repo.get(Webhook, webhook_uuid) do
      nil ->
        TechnicalError.error_404_tuple()

      webhook ->
        EventHandler.send_env_event(
          webhook.environment_id,
          webhook.action,
          webhook.props,
          payload
        )
    end
  end
end
