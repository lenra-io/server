defmodule IdentityWeb.OAuthHelpers do
  @moduledoc """
  Conveniences for translating OAuth scopes.
  """

  use Phoenix.HTML

  @doc """
  Render the header of the OAuth pages.
  """
  def oauth_header("consent", %{"metadata" => %{"environment_id" => _env_id}} = client) do
    content_tag :header, class: "external-client" do
      name = get_client_name(client)

      letter =
        name
        |> String.slice(0..0)
        |> String.upcase()

      content_tag :ul do
        [
          content_tag(:li, name,
            class: "logo",
            "data-letter": letter,
            "data-color": "blue"
          ),
          content_tag(:li, "Lenra")
        ]
      end
    end
  end

  def oauth_header(_context, %{"metadata" => %{"environment_id" => _env_id}} = client) do
    content_tag :header, class: "external-client" do
      name = get_client_name(client)

      letter =
        name
        |> String.slice(0..0)
        |> String.upcase()

      [
        content_tag(:h1, name,
          class: "logo",
          "data-letter": letter,
          "data-color": "blue"
        ),
        content_tag :p do
          [
            "Powered by ",
            content_tag(:a, "Lenra", href: "https://lenra.io")
          ]
        end
      ]
    end
  end

  def oauth_header(_context, _client) do
    content_tag :header do
      content_tag(:h1, "Lenra")
    end
  end

  @doc """
  Get the OAuth client name.
  """
  def get_client_name(%{"metadata" => %{"environment_id" => env_id}}) do
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
end
