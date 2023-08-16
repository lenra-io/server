defmodule IdentityWeb.OAuthHelpers do
  @moduledoc """
  Conveniences for translating OAuth scopes.
  """

  use Phoenix.HTML

  @doc """
  Get the OAuth client name.
  """
  def get_client_name(%{"metadata" => %{"environment_id" => env_id}}) do
    # TODO: get the app name from the environment id
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
