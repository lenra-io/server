defmodule Lenra.StripeHandler do
  alias Lenra.Repo
  alias Lenra.Subscriptions.Subscription
  require Logger
  @behaviour Stripe.WebhookHandler

  @impl true
  def handle_event(%Stripe.Event{type: "checkout.session.completed", data: %{object: %{payment_status: "paid"}}} = event) do
    # Create subscription for app_id in metadata of event, plan a are in metadat set start_date to today and end_date today + one month or one year
    end_date =
      case event.data.object.metadata["plan"] do
        "month" ->
          {:ok, today} = DateTime.now("Etc/UTC")
          days_this_month = Date.days_in_month(today)
          first_of_next   = Date.add(today, days_this_month - today.day + 1)
          days_next_month = Date.days_in_month(first_of_next)
          Date.add(first_of_next, min(today.day, days_next_month) - 1)

        "year" ->
          {:ok, today} = DateTime.now("Etc/UTC")
          Date.add(today, 365)
      end

    Subscription.new(%{
      application_id: event.data.object.metadata["app_id"],
      start_date: Date.utc_today(),
      end_date: end_date,
      plan: event.data.object.metadata["plan"]
    })
    |> Repo.insert()
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
