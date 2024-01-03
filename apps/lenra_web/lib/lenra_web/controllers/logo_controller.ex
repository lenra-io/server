defmodule LenraWeb.LogosController do
  use LenraWeb, :controller

  use LenraWeb.Policy,
    module: LenraWeb.LogosController.Policy

  alias Lenra.Apps

  def get_image_content(conn, %{"image_id" => image_id}) do
    {:ok, image} = Apps.fetch_image(image_id)

    conn
    |> put_resp_content_type(image.type)
    |> Plug.Conn.send_resp(:ok, image.data)
  end

  @spec put_logo(any(), map()) :: any()
  def put_logo(conn, %{"app_id" => _app_id, "env_id" => env_id} = params) do
    with {:ok, env} <- Apps.fetch_env(env_id),
         :ok <- allow(conn, env),
         user <- LenraWeb.Auth.current_resource(conn),
         decoded_data <- decode_data(params),
         {:ok, %{new_logo: logo}} <-
           Apps.set_logo(user.id, Map.merge(decoded_data, %{"app_id" => env.application_id, "env_id" => env.id})) do
      conn
      |> reply(logo)
    end
  end

  def put_logo(conn, %{"app_id" => app_id} = params) do
    with {:ok, app} <- Apps.fetch_app(app_id),
         :ok <- allow(conn, app),
         user <- LenraWeb.Auth.current_resource(conn),
         decoded_data <- decode_data(params),
         {:ok, %{new_logo: logo}} <- Apps.set_logo(user.id, Map.merge(decoded_data, %{"app_id" => app.id})) do
      conn
      |> reply(logo)
    end
  end

  # TODO: check the "data" and "type" types
  defp decode_data(%{"data" => data, "type" => type}) do
    %{"data" => Base.decode64!(data), "type" => type}
  end
end

defmodule LenraWeb.LogosController.Policy do
  alias Lenra.Accounts.User
  alias Lenra.Apps.App
  alias Lenra.Apps.Environment

  @impl Bouncer.Policy
  def authorize(:put_logo, %User{id: user_id}, %Environment{creator_id: user_id}), do: true
  def authorize(:put_logo, %User{id: user_id}, %App{creator_id: user_id}), do: true

  # credo:disable-for-next-line Credo.Check.Readability.StrictModuleLayout
  use LenraWeb.Policy.Default
end
