defmodule LenraWeb.LogosController do
  use LenraWeb, :controller

  use LenraWeb.Policy,
    module: LenraWeb.LogosController.Policy

  alias Lenra.Apps

  defp get_app_and_allow(conn, %{"app_id" => app_id_str}) do
    with {app_id, _} <- Integer.parse(app_id_str),
         {:ok, app} <- Apps.fetch_app(app_id),
         :ok <- allow(conn, app) do
      {:ok, app}
    end
  end

  defp get_app_env_and_allow(conn, %{"app_id" => app_id_str, "env_id" => env_id_str}) do
    with {app_id, _} <- Integer.parse(app_id_str),
         {env_id, _} <- Integer.parse(env_id_str),
         {:ok, env} <- Apps.fetch_app_env(app_id, env_id),
         app <- Map.get(env, :application),
         :ok <- allow(conn, %{app: app, env: env}) do
      {:ok, app, env}
    end
  end

  def get_image_content(conn, %{"image_id" => image_id}) do
    {:ok, image} = Apps.fetch_image(image_id)

    conn
    |> put_resp_content_type(image.type)
    |> Plug.Conn.send_resp(:ok, image.data)
  end

  def put_logo(conn, %{"app_id" => _app_id, "env_id" => _env_id} = params) do
    with {:ok, app, env} <- get_app_env_and_allow(conn, params),
         user <- LenraWeb.Auth.current_resource(conn),
         decoded_data <- decode_data(params),
         {:ok, %{new_logo: logo}} <-
           Apps.set_logo(user.id, Map.merge(decoded_data, %{"app_id" => app.id, "env_id" => env.id})) do
      conn
      |> reply(logo)
    end
  end

  def put_logo(conn, %{"app_id" => _app_id} = params) do
    with {:ok, app} <- get_app_and_allow(conn, params),
         user <- LenraWeb.Auth.current_resource(conn),
         decoded_data <- decode_data(params),
         {:ok, %{new_logo: logo}} <- Apps.set_logo(user.id, Map.merge(decoded_data, %{"app_id" => app.id})) do
      conn
      |> reply(logo)
    end
  end

  defp decode_data(%{"data" => data, "type" => type}) when is_binary(data) and is_binary(type) do
    %{"data" => Base.decode64!(data), "type" => type}
  end
end

defmodule LenraWeb.LogosController.Policy do
  alias Lenra.Accounts.User
  alias Lenra.Apps.App
  alias Lenra.Apps.Environment

  @impl Bouncer.Policy
  def authorize(:put_logo, %User{id: user_id}, %App{creator_id: user_id}), do: true

  def authorize(:put_logo, %User{id: user_id}, %{
        app: %App{id: app_id, creator_id: user_id},
        env: %Environment{application_id: app_id}
      }),
      do: true

  # credo:disable-for-next-line Credo.Check.Readability.StrictModuleLayout
  use LenraWeb.Policy.Default
end
