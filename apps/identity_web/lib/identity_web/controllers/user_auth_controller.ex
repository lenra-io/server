defmodule IdentityWeb.UserAuthController do
  alias Lenra.Legal
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

  # Check if the user has already have a verified email and has accepted the latest CGU.
  defp redirect_next_step(conn, user) do
    remember = get_session(conn, :remember)
    login_challenge = get_session(conn, :login_challenge)

    redirect_next_step(conn, user, login_challenge, remember)
  end

  defp redirect_next_step(conn, user, login_challenge, remember) do
    cond do
      # check e-mail verification
      user.role == :unverified_user ->
        # send verification email
        Accounts.resend_registration_code(user)
        # redirect to verification page
        redirect(conn,
          to: Routes.user_auth_path(conn, :check_email_page)
        )

      # check CGU update
      !Lenra.Legal.user_accepted_latest_cgu?(user.id) ->
        # TODO: redirect to CGU page
        redirect(conn,
          to: Routes.user_auth_path(conn, :validate_cgu_page)
        )

      # accept login
      true ->
        {:ok, accept_response} =
          HydraHelper.accept_login(login_challenge, to_string(user.id), remember)

        conn
        |> clear_session()
        |> redirect(external: accept_response.body["redirect_to"])
    end
  end

  defp render_cgu_page(conn, lang \\ "en", error_message \\ nil) do
    {:ok, cgu} = Legal.get_latest_cgu()

    cgu_text =
      Application.app_dir(:identity_web, "priv/static/cgu/CGU_#{lang}_#{cgu.version}.html")
      |> File.read!()

    render(conn, "cgu-validation.html",
      error_message: error_message,
      lang: lang,
      cgu_id: cgu.id,
      cgu_text: cgu_text
    )
  end

  #################
  ## Controllers ##
  #################

  # The "New" show the login/register form to the user if not already logged in.
  def new(conn, %{"login_challenge" => login_challenge}) do
    {:ok, response} = HydraHelper.get_login_request(login_challenge)

    if response.body["skip"] do
      # Can do logic stuff here like update the session.
      # The user is already logged in, skip login and redirect.

      redirect_next_step(conn, Accounts.get_user(response.body["subject"]), login_challenge, true)
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
        conn
        |> put_session(:user_id, user.id)
        |> put_session(:remember, remember == "true")
        |> put_session(:login_challenge, login_challenge)
        |> redirect_next_step(user)

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
        conn
        |> put_session(:user_id, user.id)
        |> put_session(:login_challenge, login_challenge)
        |> redirect_next_step(user)

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

  # Logout the user and reject the login request.
  def logout(conn, _params) do
    login_challenge = get_session(conn, :login_challenge)

    {:ok, accept_response} =
      HydraHelper.reject_login(login_challenge, "User logged out")

    conn
    |> clear_session()
    |> redirect(external: accept_response.body["redirect_to"])
  end

  ### EMAIL CHECK ###

  # Show the email validation form.
  def check_email_page(conn, _params) do
    # {:ok, _response} = HydraHelper.get_login_request(login_challenge)

    # client = response.body["client"]
    render(conn, "email-token.html", error_message: nil)
  end

  # Handle the email validation form and login the user if the CGU are accepted.
  def check_email_token(conn, %{"token" => token}) do
    user_id = get_session(conn, :user_id)

    IO.inspect("cookie user")
    IO.inspect(user_id)

    case Accounts.get_user(user_id)
         |> Accounts.validate_user(token) do
      {:ok, %{updated_user: user}} ->
        redirect_next_step(conn, user)

      _error ->
        render(conn, "email-token.html", error_message: "Invalid token")
    end
  end

  def check_email_token(_conn, _params),
    do: throw("No token passed.")

  # The "create" handle the register form
  def resend_check_email_token(conn, _params) do
    user_id = get_session(conn, :user_id)

    {:ok, _any} =
      Accounts.get_user(user_id)
      |> Accounts.resend_registration_code()

    json(conn, %{})
  end

  ### CGU VALIDATION ###

  # Show the email validation form.
  def validate_cgu_page(conn, %{"lang" => lang}) do
    render_cgu_page(conn, lang)
  end

  # Show the email validation form.
  def validate_cgu_page(conn, _params) do
    render_cgu_page(conn)
  end

  # Handle the email validation form and login the user if the CGU are accepted.
  def validate_cgu(conn, %{"cgu_id" => cgu_id, "lang" => lang}) do
    user_id = get_session(conn, :user_id)

    IO.inspect("cookie user")
    IO.inspect(user_id)

    case Legal.accept_cgu(cgu_id, user_id) do
      {:ok, _} ->
        redirect_next_step(conn, Accounts.get_user(user_id))

      _error ->
        render_cgu_page(
          conn,
          lang,
          "The validated terms and conditions are not the latest. Please try again."
        )
    end
  end
end
