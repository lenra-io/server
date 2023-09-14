defmodule Lenra.Subscriptions do
  import Ecto.Query

  alias ApplicationRunner.ApplicationServices
  alias Lenra.Repo
  alias Lenra.Subscriptions.Subscription

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
end
