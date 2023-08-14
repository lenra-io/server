defmodule IdentityWeb.UserConsentController do
  use IdentityWeb, :controller

  alias Lenra.Errors.BusinessError
  require Logger

  #################
  ## Controllers ##
  #################

  def index(conn, %{"consent_challenge" => consent_challenge}) do
    # Get the consent request informations
    {:ok, response} = HydraApi.get_consent_request(consent_challenge)

    # if "skip" == true, the consent have already been granted.
    # We can directly accept the consent and redirect.
    if response.body["skip"] do
      # Consent
      {:ok, accept_response} =
        HydraApi.accept_consent(
          consent_challenge,
          response.body["requested_scope"],
          response.body["requested_access_token_audience"],
          # Session data
          %{
            access_token: %{},
            id_token: %{}
          }
        )

      # Redirect to hydra.
      redirect(conn, external: accept_response.body["redirect_to"])
    else
      IO.inspect(response.body["client"])

      # If we do not skip, get the user and show the consent page.
      case Lenra.Accounts.get_user(response.body["subject"]) do
        nil ->
          BusinessError.invalid_token_tuple()

        user ->
          # The "consent_challenge" is sent back using a hiddend field.
          # Here, the "client" is an object with additionnal informations.
          # The "requested_scope" are just a list of string.
          # We could create objects in the DB or just statically explain what the scope do.
          render(conn, "consent.html",
            user: user,
            scopes: response.body["requested_scope"],
            client: response.body["client"],
            action: :consent,
            consent_challenge: consent_challenge
          )
      end
    end
  end

  def consent(conn, %{"accept" => "false", "consent_challenge" => consent_challenge}) do
    # Here, the user denied the consent by clicking on "reject" button.
    # We tell hydra that the user rejected the consent.
    {:ok, response} = HydraApi.reject_consent(consent_challenge)

    # Then redirect to hydra.
    redirect(conn, external: response.body["redirect_to"])
  end

  def consent(conn, %{
        "accept" => "true",
        "consent_challenge" => consent_challenge,
        "remember_me" => remember
      }) do
    # Here, the user accepted the consent by clicking on "accept" button.

    {:ok, response} = HydraApi.get_consent_request(consent_challenge)

    {:ok, accept_response} =
      HydraApi.accept_consent(
        consent_challenge,
        response.body["requested_scope"],
        response.body["requested_access_token_audience"],
        # We can add data to the token if needed.
        %{
          # This data will be available when introspecting the token. Try to avoid sensitive information here,
          # unless you limit who can introspect tokens.
          access_token: %{},

          # This data will be available in the ID token.
          # The ID Token is the OpenId token that contain user informations.
          # See https://www.ory.sh/docs/oauth2-oidc/overview/oidc-concepts#the-id-token
          id_token: %{}
        },
        remember == "true"
      )

    redirect(conn, external: accept_response.body["redirect_to"])
  end
end
