defmodule Lenra.StripeHandler do
  alias Lenra.Subscriptions.Subscription
  require Logger
  @behaviour Stripe.WebhookHandler

  @impl true
  def handle_event(%Stripe.Event{type: "charge.succeeded", data: %{object: %{payment_status: "paid"}}} = event) do
    # Create subscription for app_id in metadata of event, plan a are in metadat set start_date to today and end_date today + one month or one year
    end_date =
      case event.data.object.metadatsa.plan do
        "month" ->
          today = DateTime.now("Etc/UTC")
          Calendar.DateTime.add(today, {1, :months})

        "year" ->
          today = DateTime.now("Etc/UTC")
          Calendar.DateTime.add(today, {1, :years})
      end

    Subscription.new(%{
      aap_id: event.data.object.metadata.app_id,
      start_date: Date.utc_today(),
      end_date: end_date
    })
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
