defmodule Lenra.Subscriptions do
  import Ecto.Query

  alias Lenra.Errors.BusinessError
  alias ApplicationRunner.ApplicationServices
  alias Lenra.Repo
  alias Lenra.Subscriptions.Subscription
  alias Lenra.Accounts.User

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
  def subscriptioon_expires() do
  end

  def create_customer_or_get_customer(user) do
    case user.stripe_id do
      nil ->
        # Transaction ?
        with {:ok, %Stripe.Customer{} = customer} <- Stripe.Customer.create(%{email: user.email}),
             {:ok, _updated_user} <- User.update(user, %{stripe_id: customer.id}) |> Repo.update() do
          customer.id
        else
          {:error, _} ->
            Logger.error("#{__MODULE__} Error when creating customer")
            nil
        end

      _ ->
        user.stripe_id
    end
  end

  def create_checkout(
        %{
          "plan" => plan,
          "mode" => mode,
          "customer" => customer,
          "success_url" => success_url,
          "cancel_url" => cancel_url
        },
        app
      )
      when mode in ["payment", "subscription"] do
    case Stripe.Product.retrieve(app.id) do
      {:ok, %Stripe.Product{}} ->
        handle_create_session(plan, success_url, cancel_url, mode, plan, customer, app.id)

      {:error, _} ->
        create_product(app.id, app.name)
        handle_create_session(plan, success_url, cancel_url, mode, plan, customer, app.id)
    end
    |> case do
      {:ok, session} ->
        session.id

      {:error, error} ->
        BusinessError.stripe_error(error)
    end
  end

  def create_product(app_id, app_name) do
    with {:ok, %Stripe.Product{} = product} <-
           Stripe.Product.create(%{
             name: app_name,
             id: app_id
           }) do
      Stripe.Price.create(%{
        unit_amount: 8,
        currency: "eur",
        recurring: %{
          interval: "month"
        },
        product: product.id
      })

      Stripe.Price.create(%{
        unit_amount: 80,
        currency: "eur",
        recurring: %{
          interval: "year"
        },
        product: product.id
      })

      product.id
    end
  end

  @spec handle_create_session(
          binary(),
          binary(),
          binary(),
          binary(),
          integer(),
          binary(),
          integer()
        ) ::
          {:ok, Stripe.Session.t()} | {:error, Stripe.Error.t()}
  def handle_create_session(plan, success_url, cancel_url, mode, product_id, customer, app_id) do
    stripe_coupon = Application.get_env(:lenra, :stripe_coupon, nil)

    with {:ok, %Stripe.SearchResult{data: [%{id: price_id}]}} =
           Stripe.Price.search(%{
             query: "product:#{product_id} recurring:interval:#{plan}",
             limit: 1
           }) do
      Stripe.Session.create(%{
        success_url: success_url,
        cancel_url: cancel_url,
        mode: mode,
        line_items: [
          %{
            price: price_id,
            quantity: 1
          }
        ],
        customer: customer,
        metadata: %{"app_id" => app_id},
        discounts: [
          %{
            promotion_code: stripe_coupon
          }
        ]
      })
    end
  end
end
