defmodule LenraWeb.WebhooksController do
  use LenraWeb, :controller

  use LenraWeb.Policy,
    module: LenraWeb.BuildsController.Policy

  alias Lenra.Apps

  def index(conn, _params) do

  end

  def create(conn, %{"action" => action, "props" => props} = params) do

  end
end

defmodule LenraWeb.WebhooksController.Policy do
  alias Lenra.Accounts.User
  alias Lenra.Apps.{App, Build}

  @impl Bouncer.Policy
  def authorize(:index, %User{id: user_id}, %App{creator_id: user_id}), do: true
  def authorize(:create, %User{id: user_id}, %App{creator_id: user_id}), do: true
  def authorize(:update, %User{id: user_id}, %Build{creator_id: user_id}), do: true

  # credo:disable-for-next-line Credo.Check.Readability.StrictModuleLayout
  use LenraWeb.Policy.Default
end
