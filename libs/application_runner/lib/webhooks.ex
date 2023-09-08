defmodule ApplicationRunner.Webhooks do
  @moduledoc """
    ApplicationRunner.Webhooks manages Webhooks.
  """

  alias ApplicationRunner.Webhooks

  defdelegate create(env_id, params), to: Webhooks.WebhookServices
  defdelegate app_create(token_params, params), to: Webhooks.WebhookServices
  defdelegate get(env_id), to: Webhooks.WebhookServices
  defdelegate get(env_id, user_id), to: Webhooks.WebhookServices
  defdelegate trigger(webhook_uuid, payload), to: Webhooks.WebhookServices

  defdelegate new(env_id, params), to: Webhooks.Webhook
end
