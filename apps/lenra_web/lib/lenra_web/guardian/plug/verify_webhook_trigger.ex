defmodule LenraWeb.Plug.VerifyWebhookTrigger do
  @moduledoc """
  Plug that checks whether the webhook trigger should be authorized or not.
  """

  alias Lenra.Errors.BusinessError
  alias ApplicationRunner.Webhooks.WebhookServices

  def init(opts), do: opts

  def call(conn, _opts) do
    with %{"app_uuid" => app_uuid, "webhook_uuid" => webhook_uuid} <- conn.path_params,
         webhook <-
           webhook_uuid
           |> WebhookServices.get_by_uuid()
           |> Lenra.Apps.Webhook.embed()
           |> Lenra.Repo.preload(environment: [:application]),
         true <- webhook.environment.application.service_name == app_uuid do
      conn
    else
      _ ->
        translated_error = LenraCommonWeb.ErrorHelpers.translate_error(BusinessError.forbidden())

        conn
        |> Phoenix.Controller.put_view(LenraWeb.ErrorView)
        |> Plug.Conn.put_status(403)
        |> Phoenix.Controller.render("403.json", error: translated_error)
        |> Plug.Conn.halt()
    end
  end
end
