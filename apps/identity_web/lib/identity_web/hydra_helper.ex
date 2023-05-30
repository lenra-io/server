defmodule IdentityWeb.HydraHelper do
  # 30 days In seconds
  @remember_for 60 * 60 * 24 * 30

  def get_login_request(login_challenge) do
    ORY.Hydra.get_login_request(%{login_challenge: login_challenge})
    |> ORY.Hydra.request(hydra_config())
  end

  def accept_login(login_challenge, subject, remember \\ false) do
    IO.inspect({"accept_login", remember})

    ORY.Hydra.accept_login_request(%{
      login_challenge: login_challenge,
      subject: subject,
      remember: remember,
      remember_for: @remember_for
    })
    |> ORY.Hydra.request(hydra_config())
  end

  def get_consent_request(consent_challenge) do
    # The "Consent request" contain data about the current consent request.
    # We request hydra to retreive these data.
    ORY.Hydra.get_consent_request(%{consent_challenge: consent_challenge})
    |> ORY.Hydra.request(hydra_config())
  end

  def accept_consent(consent_challenge, grant_scope, grant_access_token_audience, session, remember \\ false) do
    IO.inspect({"accept_consent", remember})

    ORY.Hydra.accept_consent_request(%{
      consent_challenge: consent_challenge,
      grant_scope: grant_scope,
      grant_access_token_audience: grant_access_token_audience,
      session: session,
      remember: remember,
      remember_for: @remember_for
    })
    |> ORY.Hydra.request(hydra_config())
  end

  def reject_consent(consent_challenge) do
    ORY.Hydra.reject_consent_request(%{
      consent_challenge: consent_challenge,
      error: :consent_denied,
      error_description: "The resource owner did not consent."
    })
    |> ORY.Hydra.request(hydra_config())
  end

  def hydra_url do
    Application.fetch_env!(:identity_web, :hydra_url)
  end

  def hydra_config do
    %{url: hydra_url()}
  end
end
