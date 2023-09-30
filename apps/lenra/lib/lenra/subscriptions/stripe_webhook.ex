defmodule Lenra.StripeHandler do
  @moduledoc """
    Lenra.StripeHandler handle stripe events
  """
  @behaviour Stripe.WebhookHandler

  alias ApplicationRunner.ApplicationServices
  alias Lenra.Repo
  alias Lenra.Subscriptions.Subscription
  alias LenraWeb.AppAdapter

  require Logger

  @impl true
  def handle_event(
        %Stripe.Event{
          type: "checkout.session.completed",
          data: %{object: %{payment_status: "paid"}}
        } = event
      ) do
    end_date =
      case event.data.object.metadata["plan"] do
        "month" ->
          {:ok, today} = DateTime.now("Etc/UTC")
          days_this_month = Date.days_in_month(today)
          first_of_next = Date.add(today, days_this_month - today.day + 1)
          days_next_month = Date.days_in_month(first_of_next)
          Date.add(first_of_next, min(today.day, days_next_month) - 1)

        "year" ->
          {:ok, today} = DateTime.now("Etc/UTC")
          Date.add(today, 365)
      end

    %{
      application_id: event.data.object.metadata["app_id"],
      start_date: Date.utc_today(),
      end_date: end_date,
      plan: event.data.object.metadata["plan"]
    }
    |> Subscription.new()
    |> Repo.insert()

    app =
      Lenra.Apps.App
      |> Lenra.Repo.get(event.data.object.metadata["app_id"])
      |> Lenra.Repo.preload(main_env: [environment: [deployment: [:build]]])

    if app.main_env.environment.deployment != nil do
      if app.main_env.environment.deployment.build != nil do
        function_name = AppAdapter.get_function_name(app.service_name)
        ApplicationServices.set_app_max_scale(function_name, 5)
      end
    end

    :ok
  end

  @impl true
  def handle_event(%Stripe.Event{} = event) do
    Logger.info("Stripe event #{inspect(event)}")
    :ok
  end

  # Return HTTP 200 for unhandled events
  @impl true
  def handle_event(_event), do: :ok
end
