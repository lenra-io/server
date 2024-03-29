defmodule HydraApi do
  @moduledoc """
    Give some helper functions to help with OryHydra workflow.
    get/accept login request
    get/accept/reject consent request
    get hydra url/config
  """

  require Logger

  # 30 days In seconds
  @remember_days 30
  @remember_for 60 * 60 * 24 * @remember_days

  def get_remember_days do
    @remember_days
  end

  def get_login_request(login_challenge) do
    %{login_challenge: login_challenge}
    |> IdentityWeb.Hydra.get_login_request()
    |> IdentityWeb.Hydra.request(hydra_config())
  end

  def accept_login(login_challenge, subject, remember \\ false) do
    %{
      login_challenge: login_challenge,
      subject: subject,
      remember: remember,
      remember_for: @remember_for
    }
    |> IdentityWeb.Hydra.accept_login_request()
    |> IdentityWeb.Hydra.request(hydra_config())
  end

  def reject_login(login_challenge, error_description) do
    %{
      login_challenge: login_challenge,
      error_description: error_description
    }
    |> IdentityWeb.Hydra.reject_login_request()
    |> IdentityWeb.Hydra.request(hydra_config())
  end

  def get_consent_request(consent_challenge) do
    # The "Consent request" contain data about the current consent request.
    # We request hydra to retreive these data.
    %{consent_challenge: consent_challenge}
    |> IdentityWeb.Hydra.get_consent_request()
    |> IdentityWeb.Hydra.request(hydra_config())
  end

  def accept_consent(
        consent_challenge,
        grant_scope,
        grant_access_token_audience,
        session,
        remember \\ false
      ) do
    %{
      consent_challenge: consent_challenge,
      grant_scope: grant_scope,
      grant_access_token_audience: grant_access_token_audience,
      session: session,
      remember: remember,
      remember_for: @remember_for
    }
    |> IdentityWeb.Hydra.accept_consent_request()
    |> IdentityWeb.Hydra.request(hydra_config())
  end

  def reject_consent(consent_challenge) do
    %{
      consent_challenge: consent_challenge,
      error: :consent_denied,
      error_description: "The resource owner did not consent."
    }
    |> IdentityWeb.Hydra.reject_consent_request()
    |> IdentityWeb.Hydra.request(hydra_config())
  end

  def get_logout_request(logout_challenge) do
    # The "Consent request" contain data about the current consent request.
    # We request hydra to retreive these data.
    %{logout_challenge: logout_challenge}
    |> IdentityWeb.Hydra.get_logout_request()
    |> IdentityWeb.Hydra.request(hydra_config())
  end

  def accept_logout(logout_challenge) do
    %{
      logout_challenge: logout_challenge
    }
    |> IdentityWeb.Hydra.accept_logout_request()
    |> IdentityWeb.Hydra.request(hydra_config())
  end

  def introspect(token, required_scopes) do
    %{scope: required_scopes, token: token}
    |> IdentityWeb.Hydra.introspect()
    |> IdentityWeb.Hydra.request(hydra_config())
  end

  def check_token(token, required_scopes) do
    with {:ok, response} <- HydraApi.introspect(token, required_scopes),
         true <- Map.get(response.body, "active", false) do
      {:ok, response}
    else
      _error ->
        {:error, :invalid_token}
    end
  end

  def check_token_and_get_subject(token, required_scopes) do
    with {:ok, response} <- check_token(token, required_scopes) do
      subject = response.body["sub"]
      {:ok, subject, response.body}
    end
  end

  defp prepare_request(params) do
    %{
      token_endpoint_auth_method: "none",
      client_name: params.name,
      scope: Enum.join(params.scopes, " "),
      redirect_uris: params.redirect_uris,
      allowed_cors_origins: params.allowed_origins,
      skip_consent: false,
      metadata: %{
        environment_id: params.environment_id
      }
    }
  end

  def create_oauth2_client(params) do
    params
    |> prepare_request()
    |> create_hydra_client()
  end

  def update_oauth2_client(params) do
    params
    |> prepare_request()
    |> update_hydra_client(params.oauth2_client_id)
  end

  def get_hydra_client(id) do
    id
    |> IdentityWeb.Hydra.get_client()
    |> IdentityWeb.Hydra.request(hydra_config())
  end

  def create_hydra_client(params) do
    Logger.debug("Create hydra client #{inspect(params)}")

    params
    |> IdentityWeb.Hydra.create_client()
    |> IdentityWeb.Hydra.request(hydra_config())
  end

  def delete_hydra_client(id) do
    Logger.debug("Delete hydra client #{id}")

    id
    |> IdentityWeb.Hydra.delete_client()
    |> IdentityWeb.Hydra.request(hydra_config())
  end

  def update_hydra_client(params, id) do
    Logger.debug("Update hydra client #{id} to #{inspect(params)}")

    id
    |> IdentityWeb.Hydra.update_client(params)
    |> IdentityWeb.Hydra.request(hydra_config())
  end

  def hydra_url do
    Application.fetch_env!(:hydra_api, :hydra_url)
  end

  def hydra_config do
    %{url: hydra_url()}
  end
end
