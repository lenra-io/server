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
    |> ORY.Hydra.get_login_request()
    |> ORY.Hydra.request(hydra_config())
  end

  def accept_login(login_challenge, subject, remember \\ false) do
    %{
      login_challenge: login_challenge,
      subject: subject,
      remember: remember,
      remember_for: @remember_for
    }
    |> ORY.Hydra.accept_login_request()
    |> ORY.Hydra.request(hydra_config())
  end

  def reject_login(login_challenge, error_description) do
    %{
      login_challenge: login_challenge,
      error_description: error_description
    }
    |> ORY.Hydra.reject_login_request()
    |> ORY.Hydra.request(hydra_config())
  end

  def get_consent_request(consent_challenge) do
    # The "Consent request" contain data about the current consent request.
    # We request hydra to retreive these data.
    %{consent_challenge: consent_challenge}
    |> ORY.Hydra.get_consent_request()
    |> ORY.Hydra.request(hydra_config())
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
    |> ORY.Hydra.accept_consent_request()
    |> ORY.Hydra.request(hydra_config())
  end

  def reject_consent(consent_challenge) do
    %{
      consent_challenge: consent_challenge,
      error: :consent_denied,
      error_description: "The resource owner did not consent."
    }
    |> ORY.Hydra.reject_consent_request()
    |> ORY.Hydra.request(hydra_config())
  end

  def get_logout_request(logout_challenge) do
    # The "Consent request" contain data about the current consent request.
    # We request hydra to retreive these data.
    %{logout_challenge: logout_challenge}
    |> ORY.Hydra.get_logout_request()
    |> ORY.Hydra.request(hydra_config())
  end

  def accept_logout(logout_challenge) do
    %{
      logout_challenge: logout_challenge
    }
    |> ORY.Hydra.accept_logout_request()
    |> ORY.Hydra.request(hydra_config())
  end

  def introspect(token, required_scopes) do
    %{scope: required_scopes, token: token}
    |> ORY.Hydra.introspect()
    |> ORY.Hydra.request(hydra_config())
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

  def create_lenra_backoffice_hydra_client do
    app_url = Application.fetch_env!(:lenra, :lenra_app_url)

    create_hydra_client(
      "Lenra Backoffice",
      "profile store manage:account manage:apps",
      ["#{app_url}/redirect.html"]
    )
  end

  def create_lenra_hydra_client do
    app_url = Application.fetch_env!(:lenra, :lenra_app_url)

    create_hydra_client(
      "Lenra Client",
      "profile store resources manage:account ",
      ["#{app_url}/redirect.html"]
    )
  end

  @spec create_oauth_client(number(), String.t(), String.t(), list(String.t())) ::
          {:ok, ORY.Hydra.Response.t()} | {:error, ORY.Hydra.Response.t() | any}
  def create_oauth_client(env_id, client_name, scopes, redirect_uris) do
    create_hydra_client(client_name, scopes, redirect_uris, %{
      metadata: %{
        env_id: env_id
      }
    })
  end

  defp create_hydra_client(client_name, scopes, redirect_uris, additionnal_params \\ %{}) do
    Logger.debug("Creating Hydra client #{client_name}")

    %{
      token_endpoint_auth_method: "none",
      client_name: client_name,
      scope: scopes,
      redirect_uris: redirect_uris,
      skip_consent: false
    }
    |> Map.merge(additionnal_params)
    |> ORY.Hydra.create_client()
    |> ORY.Hydra.request(hydra_config())
  end

  def hydra_url do
    Application.fetch_env!(:hydra_api, :hydra_url)
  end

  def hydra_config do
    %{url: hydra_url()}
  end
end
