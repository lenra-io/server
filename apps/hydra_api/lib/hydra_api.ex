defmodule HydraApi do
  @moduledoc """
    Give some helper functions to help with OryHydra workflow.
    get/accept login request
    get/accept/reject consent request
    get hydra url/config
  """

  alias Lenra.Accounts
  alias Lenra

  # 30 days In seconds
  @remember_for 60 * 60 * 24 * 30

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
      _ -> {:error, :invalid_token}
    end
  end

  def check_token_and_get_resource(token, required_scopes) do
    with {:ok, response} <- check_token(token, required_scopes) do
      subject = response.body["sub"]

      case Accounts.get_user(subject) do
        nil ->
          {:error, :invalid_subject}

        user ->
          {:ok, user, response.body}
      end
    end
  end

  def hydra_url do
    Application.fetch_env!(:hydra_api, :hydra_url)
  end

  def hydra_config do
    %{url: hydra_url()}
  end
end
