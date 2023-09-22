defmodule Lenra.StripeHandler do
  require Logger
  @behaviour Stripe.WebhookHandler

  @impl true
  def handle_event(%Stripe.Event{} = event) do
    Logger.info("Stripe event #{inspect(event)}")
    :ok
  end

  # Return HTTP 200 for unhandled events
  @impl true
  def handle_event(_event), do: :ok
end
