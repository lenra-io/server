defmodule Lenra.Subscriptions do
  alias Lenra.Accounts.User
  alias LenraCommon.Errors
  alias Lenra.Errors.TechnicalError
  require Logger

  def create_customer_or_get_customer(user) do
    case user.stripe_id do
      nil ->
        # Transaction ?
        with %Stripe.Customer{} = customer <- Stripe.Customer.create(email: user.email),
             :ok <- User.update(user, %{stripe_id: customer.id}) do
          customer.id
        end

      _ ->
        user.stripe_id
    end
  end

  def create_checkout(
        %{"plan" => plan, "mode" => mode, "customer" => customer, "success_url" => success_url},
        app
      )
      when mode in ["payment", "subscription"] do
    session =
      case Stripe.Product.retrieve(app.id) do
        {:ok, %Stripe.Product{} = product} ->
          handle_create_session(plan, success_url, mode, plan, customer)

        {:error, _} ->
          product = create_product(app.id, app.name)
          handle_create_session(plan, success_url, mode, plan, customer)
      end

    session.id
  end

  def create_product(app_id, app_name) do
    with %Stripe.Product{} = product <-
           Stripe.Product.create(
             name: app_name,
             description: "Lenra subscription",
             id: app_id
           ) do
      Stripe.Price.create(
        unit_amount: 8,
        currency: "eur",
        recurring: %{
          interval: "month"
        },
        product: product.id
      )

      Stripe.Price.create(
        unit_amount: 80,
        currency: "eur",
        recurring: %{
          interval: "year"
        },
        product: product.id
      )

      product.id
    end
  end

  def handle_create_session(plan, success_url, mode, product_id, customer) do
    Stripe.Session.create(
      success_url: success_url,
      mode: mode,
      line_items: [
        price: Stripe.Price.search(product: product_id, recurring: %{interval: plan}),
        quantity: 1
      ],
      customer: customer
    )
  end
end
