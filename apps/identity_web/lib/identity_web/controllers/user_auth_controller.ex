defmodule IdentityWeb.UserAuthController do
  use IdentityWeb, :controller

  alias Lenra.Accounts
  alias Lenra.Accounts.Password
  alias Lenra.Accounts.User

  alias IdentityWeb.HydraHelper

  ######################
  ## Helper functions ##
  ######################

  defp register_changeset_or_new(nil),
    do: Accounts.User.registration_changeset(%User{password: [%Password{}]}, %{})

  defp register_changeset_or_new(changeset), do: changeset

  #################
  ## Controllers ##
  #################

  # The "New" show the login/register form to the user if not already logged in.
  def new(conn, %{"login_challenge" => login_challenge}) do
    {:ok, response} = HydraHelper.get_login_request(login_challenge)

    if response.body["skip"] do
      # Can do logic stuff here like update the session.
      # The user is already logged in, skip login and redirect.

      # TODO: check CGU update
      {:ok, accept_response} =
        HydraHelper.accept_login(login_challenge, response.body["subject"], true)

      redirect(conn, external: accept_response.body["redirect_to"])
    else
      # client = response.body["client"]
      render(conn, "new.html",
        submit_action: "register",
        error_message: nil,
        login_challenge: login_challenge,
        changeset: register_changeset_or_new(nil)
      )
    end
  end

  def new(_conn, _params),
    do: throw("Expected a login challenge to be set but received none")

  # The "login" handle the login form and login the user if credentials are correct.
  def login(conn, %{"user" => %{"login_challenge" => login_challenge} = user_params} = params) do
    %{
      "email" => email,
      "password" => %{"0" => %{"password" => password}},
      "remember_me" => remember
    } = user_params

    case Accounts.login_user(email, password) do
      {:ok, user} ->
        cond do
          # check e-mail verification
          user.role == :unverified_user ->
            IO.inspect("unverified user")
            # send verification email
            Accounts.resend_registration_code(user)
            # redirect to verification page
            redirect(conn,
              to:
                Routes.user_auth_path(conn, :check_email_page) <>
                  "?login_challenge=#{login_challenge}"
            )

          # check CGU update
          Lenra.Legal.user_accepted_latest_cgu?(user.id) ->
            IO.inspect("CGU not validated")

          # TODO: redirect to CGU page

          # accept login
          true ->
            {:ok, accept_response} =
              HydraHelper.accept_login(login_challenge, to_string(user.id), remember == "true")

            redirect(conn, external: accept_response.body["redirect_to"])
        end

      _error ->
        # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
        render(conn, "new.html",
          submit_action: "login",
          error_message: "Invalid email or password",
          login_challenge: login_challenge,
          changeset: register_changeset_or_new(params["user"])
        )
    end
  end

  def login(_conn, _params),
    do: throw("No login_challenge in login form POST. It should be passed in the render.")

  # The "create" handle the register form
  def create(conn, %{
        "user" => %{"login_challenge" => login_challenge} = user_register_params
      }) do
    case Accounts.register_user_new(user_register_params) do
      {:ok, %{inserted_user: user}} ->
        {:ok, accept_response} =
          HydraHelper.accept_login(login_challenge, to_string(user.id), false)

        redirect(conn, external: accept_response.body["redirect_to"])

      {:error, :inserted_user, %Ecto.Changeset{} = changeset, _done} ->
        render(conn, "new.html",
          submit_action: "register",
          error_message: nil,
          changeset: register_changeset_or_new(changeset),
          login_challenge: login_challenge
        )

      {:error, :password, changeset, _done} ->
        render(conn, "new.html",
          submit_action: "register",
          error_message: nil,
          changeset: register_changeset_or_new(changeset),
          login_challenge: login_challenge
        )
    end
  end

  def create(_conn, _params),
    do: throw("No login_challenge in login form POST. It should be passed in the render.")

  ### EMAIL CHECK ###

  # Show the email validation form.
  def check_email_page(conn, %{"login_challenge" => login_challenge}) do
    {:ok, response} = HydraHelper.get_login_request(login_challenge)

    # client = response.body["client"]
    render(conn, "email-token.html",
      error_message: nil,
      login_challenge: login_challenge
    )
  end

  def check_email_page(_conn, _params),
    do: throw("Expected a login challenge to be set but received none")

  # Handle the email validation form and login the user if the CGU are accepted.
  def check_email_token(conn, %{"login_challenge" => login_challenge, "token" => token} = params) do
    user = get_session(conn, :user)
    remember = get_session(conn, :remember)

    IO.inspect("cookie user")
    IO.inspect(user)

    case Accounts.validate_user(user, token) do
      {:ok, user} ->
        cond do
          # check CGU update
          Lenra.Legal.user_accepted_latest_cgu?(user.id) ->
            IO.inspect("CGU not validated")

          # TODO: redirect to CGU page

          # accept login
          true ->
            {:ok, accept_response} =
              HydraHelper.accept_login(login_challenge, to_string(user.id), remember == "true")

            redirect(conn, external: accept_response.body["redirect_to"])
        end

      _error ->
        # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
        render(conn, "email-token.html",
          error_message: "Invalid email or password",
          login_challenge: login_challenge
        )
    end
  end

  def check_email_token(_conn, _params),
    do: throw("No login_challenge in email check form POST. It should be passed in the render.")

  # The "create" handle the register form
  def resend_check_email_token(conn, _params) do
    user = get_session(conn, :user)
    {:ok, _any} = Accounts.resend_registration_code(user)
    reply(conn)
  end
end
