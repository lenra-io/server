defmodule IdentityWeb.OAuthHelpers do
  @moduledoc """
  Conveniences for translating OAuth scopes.
  """
  alias Lenra.Apps

  use Phoenix.HTML

  @colors ["blue", "green", "red", "yellow"]
  @colors_length length(@colors)

  def get_color(name) when is_binary(name) do
    pos =
      :crypto.hash(:md5, name)
      |> :binary.bin_to_list()
      |> List.last()
      |> rem(@colors_length)

    Enum.at(@colors, pos)
  end

  @doc """
  Render the header of the OAuth pages.
  """
  def oauth_header("consent", %{"metadata" => %{"environment_id" => env_id}})
      when is_integer(env_id) or is_binary(env_id) do
    content_tag :header, class: "external-client" do
      {:ok, app} = Lenra.Apps.fetch_app_for_env(env_id)

      [
        content_tag :ul do
          [
            create_logo_tag(app, env_id, :li),
            content_tag(:li, "Lenra", class: "lenra")
          ]
        end,
        content_tag(
          :h1,
          Gettext.gettext(IdentityWeb.Gettext, "You've been invited to use an app")
        )
      ]
    end
  end

  def oauth_header(_context, %{"metadata" => %{"environment_id" => env_id}})
      when is_integer(env_id) or is_binary(env_id) do
    content_tag :header, class: "external-client" do
      {:ok, app} = Lenra.Apps.fetch_app_for_env(env_id)

      [
        create_logo_tag(app, env_id, :h1),
        content_tag :p do
          [
            "Powered by ",
            content_tag(:a, "Lenra", href: "https://www.lenra.io", target: "_blank")
          ]
        end
      ]
    end
  end

  def oauth_header(_context, client) do
    content_tag :header do
      content_tag(:h1, "Lenra")
    end
  end

  @doc """
  Get the OAuth client name.
  """
  def get_client_name(%{"metadata" => %{"environment_id" => env_id}})
      when is_binary(env_id) do
    # get the app name from the environment id
    {:ok, app} = Lenra.Apps.fetch_app_for_env(env_id)
    app.name
  end

  def get_client_name(%{"client_name" => name}) do
    name
  end

  @doc """
  Get a scope description translscope.ated using gettext.
  """
  def get_translated_scope_description(scope) do
    Gettext.dgettext(IdentityWeb.Gettext, "oauth", "scope." <> scope)
  end

  defp create_logo_tag(app, env_id, tagname) do
    logo = Apps.get_logo(app.id, env_id)

    case logo do
      nil ->
        letter =
          app.name
          |> String.slice(0..0)
          |> String.upcase()

        content_tag(tagname, app.name,
          class: "logo",
          "data-letter": letter,
          "data-color": get_color(app.service_name)
        )

      _ ->
        content_tag tagname, class: "logo" do
          img_tag("http://localhost:4000/apps/images/#{logo.image_id}", alt: app.name)
        end
    end
  end
end
