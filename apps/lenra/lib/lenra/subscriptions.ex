defmodule Lenra.Subscriptions do
  @moduledoc """
    Lenra.Subscriptions represent subscriptions schema
  """

  import Ecto.Query

  alias ApplicationRunner.ApplicationServices
  alias Lenra.Accounts.User
  alias Lenra.Errors.BusinessError
  alias Lenra.Repo
  alias Lenra.Subscriptions.Subscription

  require Logger

  def get_subscription_by_app_id(application_id) do
    Repo.one(
      from(s in Subscription,
        where:
          s.application_id == ^application_id and s.end_date >= ^Date.utc_today() and
            s.start_date <= ^Date.utc_today()
      )
    )
  end

  def get_customer_portal_url(user) do
    case Stripe.BillingPortal.Session.create(%{customer: user.stripe_id}) do
      {:ok, portal} -> portal.url
      {:error, error} -> BusinessError.stripe_error(error)
    end
  end

  @deprecated "Use Lenra.Apps.effective_env_scale_options/1"
  def get_max_replicas(application_id) do
    if get_subscription_by_app_id(application_id) != nil do
      5
    else
      1
    end
  end

  # Set max replicas of the function with 'replicas'
  def set_max_replicas(function_name, replicas) do
    ApplicationServices.set_app_labels(function_name, %{"com.openfaas.scale.max" => replicas})
  end

  # Function call by cron when subscription are ending, set application to private and set max_replicas to 1
  # def subscriptioon_expires() do
  # TODO: handle subscription expiration
  # end

  def create_customer_or_get_customer(user) do
    case user.stripe_id do
      nil ->
        # Transaction ?
        with {:ok, %Stripe.Customer{} = customer} <- Stripe.Customer.create(%{email: user.email}),
             {:ok, _updated_user} <-
               user |> User.update(%{stripe_id: customer.id}) |> Repo.update() do
          customer.id
        else
          {:error, _} = error ->
            Logger.error("#{__MODULE__} Error when creating customer")
            Logger.error(error)
            nil
        end

      _error ->
        user.stripe_id
    end
  end

  def create_checkout(
        %{
          "plan" => plan,
          "customer" => customer,
          "success_url" => success_url,
          "cancel_url" => cancel_url
        },
        app
      ) do
    if get_subscription_by_app_id(app.id) != nil do
      BusinessError.subscription_already_exist_tuple()
    else
      "#{app.id}"
      |> Stripe.Product.retrieve()
      |> case do
        {:ok, %Stripe.Product{} = product} ->
          handle_create_session(plan, success_url, cancel_url, product.id, customer, app.id)

        {:error, _} ->
          product_id = create_product(app.id, app.name)
          handle_create_session(plan, success_url, cancel_url, product_id, customer, app.id)
      end
      |> case do
        {:ok, session} ->
          session.url

        {:error, error} ->
          BusinessError.stripe_error(error)
      end
    end
  end

  def create_product(app_id, app_name) do
    with {:ok, %Stripe.Product{} = product} <-
           Stripe.Product.create(%{
             name: app_name,
             id: app_id
           }) do
      Stripe.Price.create(%{
        unit_amount: 800,
        currency: "eur",
        recurring: %{
          interval: "month"
        },
        product: product.id,
        metadata: %{
          "plan" => "month"
        },
        tax_behavior: "exclusive"
      })

      Stripe.Price.create(%{
        unit_amount: 8000,
        currency: "eur",
        recurring: %{
          interval: "year"
        },
        product: product.id,
        metadata: %{
          "plan" => "year"
        },
        tax_behavior: "exclusive"
      })

      product.id
    end
  end

  def handle_create_session(plan, success_url, cancel_url, product_id, customer, app_id) do
    stripe_coupon = Application.get_env(:lenra, :stripe_coupon, nil)

    with {:ok, %Stripe.List{} = prices} <- Stripe.Price.list(%{product: product_id}),
         %Stripe.Price{id: price_id} <-
           Enum.find(prices.data, nil, fn price -> price.metadata["plan"] == plan end) do
      session_map = %{
        success_url: success_url,
        cancel_url: cancel_url,
        mode: "subscription",
        line_items: [
          %{
            price: price_id,
            quantity: 1
          }
        ],
        customer: customer,
        metadata: %{"app_id" => app_id, "plan" => plan},
        automatic_tax: %{enabled: true},
        customer_update: %{address: "auto"}
      }

      session =
        if stripe_coupon != nil do
          session_map
          |> Map.put(:discounts, [
            %{
              promotion_code: stripe_coupon
            }
          ])
        else
          session_map
        end

      Stripe.Session.create(session)
    end
  end
end
