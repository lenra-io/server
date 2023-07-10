defmodule IdentityWeb.HydraHelper do
  @moduledoc """
    Give some helper functions to help with OryHydra workflow.
    get/accept login request
    get/accept/reject consent request
    get hydra url/config
  """

  # 30 days In seconds
  @remember_days 30
  @remember_for 60 * 60 * 24 * @remember_days

  def get_remember_days do @remember_days end


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

  def hydra_url do
    Application.fetch_env!(:identity_web, :hydra_url)
  end

  def hydra_config do
    %{url: hydra_url()}
  end
end
