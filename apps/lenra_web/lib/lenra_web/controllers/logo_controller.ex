defmodule LenraWeb.LogosController do
  use LenraWeb, :controller

  use LenraWeb.Policy,
    module: LenraWeb.BuildsController.Policy

  alias Lenra.Apps
  alias Lenra.Apps.Image

  # TODO: check the "data" and "type" types
  def put_logo(conn, %{"app_id" => app_id, "data" => data, "type" => _type} = params) do
    # transform data to binary
    params = Map.put(params, "data", Base.decode64!(data))
    # Environment id is optional
    Map.put_new(params, "env_id", nil)
    with {:ok, app} <- Apps.fetch_app(app_id),
         :ok <- allow(conn, app),
         user <- LenraWeb.Auth.current_resource(conn),
         {:ok, %{inserted_image: image}} <- Apps.set_logo(user.id, params) do
      conn
      |> reply(image)
    end
  end
end

defmodule LenraWeb.BuildsController.Policy do
  alias Lenra.Accounts.User
  alias Lenra.Apps.{App, Build}

  @impl Bouncer.Policy
  def authorize(:put_logo, %User{id: user_id}, %App{creator_id: user_id}), do: true

  # credo:disable-for-next-line Credo.Check.Readability.StrictModuleLayout
  use LenraWeb.Policy.Default
end
