defmodule IdentityWeb.UserAuthController do
  use IdentityWeb, :controller

  alias Lenra.Accounts
  alias Lenra.Accounts.Password
  alias Lenra.Accounts.User
  alias Lenra.Legal
  alias Lenra.Repo

  alias Lenra.Errors.BusinessError

  ######################
  ## Helper functions ##
  ######################

  defp register_changeset_or_new(nil),
    do: Accounts.User.registration_changeset(%User{password: [%Password{}]}, %{})

  defp register_changeset_or_new(changeset), do: changeset

  # Check if the user has already have a verified email and has accepted the latest CGS.
  defp redirect_next_step(conn, user) do
    remember = get_session(conn, :remember)
    login_challenge = get_session(conn, :login_challenge)

    redirect_next_step(conn, user, login_challenge, remember)
  end

  defp redirect_next_step(conn, user, login_challenge, remember) do
    cond do
      # check e-mail verification
      user.role == :unverified_user ->
        # redirect to verification page
        redirect(conn,
          to: Routes.user_auth_path(conn, :check_email_page)
        )

      # check CGS update
      !Lenra.Legal.user_accepted_latest_cgs?(user.id) ->
        # redirect to CGS page
        redirect(conn,
          to: Routes.user_auth_path(conn, :validate_cgs_page)
        )

      # accept login
      true ->
        {:ok, accept_response} = HydraApi.accept_login(login_challenge, to_string(user.id), remember)

        conn
        |> clear_session()
        |> redirect(external: accept_response.body["redirect_to"])
    end
  end

  defp render_cgs_page(conn, lang \\ "en", error_message \\ nil) do
    {:ok, cgs} = Legal.get_latest_cgs()

    cgs_text =
      Application.app_dir(:identity_web, "priv/static/cgs/CGS_#{lang}_#{cgs.version}.html")
      |> File.read!()

    render_with_client(conn, "cgs-validation.html",
      error_message: error_message,
      lang: lang,
      cgs_id: cgs.id,
      cgs_text: cgs_text
    )
  end

  defp get_user_with_email(nil), do: BusinessError.incorrect_email_tuple()

  defp get_user_with_email(email) do
    case Repo.get_by(User, email: String.downcase(email)) do
      nil -> BusinessError.incorrect_email_tuple()
      user -> {:ok, user}
    end
  end

  defp render_change_lost_password(conn, email, code \\ nil, error_message \\ nil)

  defp render_change_lost_password(
         conn,
         email,
         code,
         %LenraCommon.Errors.BusinessError{
           message: error_message
         }
       ) do
    render_change_lost_password(conn, email, code, error_message)
  end

  defp render_change_lost_password(
         conn,
         email,
         code,
         error_message
       )
       when is_binary(email) do
    render_change_lost_password(
      conn,
      Accounts.User.reset_password_changeset(%User{password: [%Password{}]}, %{email: email}),
      code,
      error_message
    )
  end

  defp render_change_lost_password(
         conn,
         %Ecto.Changeset{} = changeset,
         code,
         error_message
       ) do
    render_with_client(conn, "lost-password-new-password.html",
      changeset: changeset,
      code: code,
      error_message: error_message
    )
  end

  @spec render_with_client(Plug.Conn.t(), binary | atom, Keyword.t() | map | binary | atom) ::
          Plug.Conn.t()
  defp render_with_client(conn, template, assigns)
       when is_map(assigns) or is_list(assigns) do
    {:ok, response} =
      conn
      |> get_session(:login_challenge)
      |> HydraApi.get_login_request()

    render(
      conn,
      template,
      assigns ++ [client: response.body["client"]]
    )
  end

  #################
  ## Controllers ##
  #################

  # The "New" show the login/register form to the user if not already logged in.
  def new(conn, %{"login_challenge" => login_challenge}) do
    {:ok, response} = HydraApi.get_login_request(login_challenge)

    if response.body["skip"] do
      # Can do logic stuff here like update the session.
      # The user is already logged in, skip login and redirect.

      redirect_next_step(conn, Accounts.get_user(response.body["subject"]), login_challenge, true)
    else
      # client = response.body["client"]
      conn
      |> delete_session(:user_id)
      |> delete_session(:remember)
      |> delete_session(:email)
      |> put_session(:login_challenge, login_challenge)
      |> redirect(to: Routes.user_auth_path(conn, :register_page))
    end
  end

  def new(conn, _params),
    do: redirect(conn, to: Routes.user_auth_path(conn, :register_page))

  # Display the login page
  def login_page(conn, _params) do
    render_with_client(conn, "new.html",
      submit_action: "login",
      error_message: nil,
      changeset: register_changeset_or_new(nil)
    )
  end

  # The "login" handle the login form and login the user if credentials are correct.
  def login(
        conn,
        %{
          "user" => %{
            "email" => email,
            "password" => %{"0" => %{"password" => password}},
            "remember_me" => remember
          }
        }
      ) do
    case Accounts.login_user(email, password) do
      {:ok, user} ->
        conn
        |> put_session(:user_id, user.id)
        |> put_session(:remember, remember == "true")
        |> redirect_next_step(user)

      _error ->
        # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
        render_with_client(conn, "new.html",
          submit_action: "login",
          error_message: "Invalid email or password",
          changeset: register_changeset_or_new(nil)
        )
    end
  end

  def login(conn, params) do
    cancel_login(conn, params)
  end

  # Display the register page
  def register_page(conn, _params) do
    render_with_client(conn, "new.html",
      submit_action: "register",
      error_message: nil,
      changeset: register_changeset_or_new(nil)
    )
  end

  # The "create" handle the register form
  def register(conn, %{
        "user" => %{} = user_register_params
      }) do
    case Accounts.register_user_new(user_register_params) do
      {:ok, %{inserted_user: user}} ->
        conn
        |> put_session(:user_id, user.id)
        |> redirect_next_step(user)

      {:error, :inserted_user, %Ecto.Changeset{} = changeset, _done} ->
        render_with_client(conn, "new.html",
          submit_action: "register",
          error_message: nil,
          changeset: register_changeset_or_new(changeset)
        )

      {:error, :password, changeset, _done} ->
        render_with_client(conn, "new.html",
          submit_action: "register",
          error_message: nil,
          changeset: register_changeset_or_new(changeset)
        )
    end
  end

  def register(conn, params),
    do: cancel_login(conn, params)

  # Logout the user and reject the login request.
  def cancel_login(conn, _params) do
    login_challenge = get_session(conn, :login_challenge)

    {:ok, accept_response} = HydraApi.reject_login(login_challenge, "User logged out")

    conn
    |> clear_session()
    |> redirect(external: accept_response.body["redirect_to"])
  end

  # The "logout" handle the logout request.
  def logout(conn, %{"logout_challenge" => logout_challenge}) do
    {:ok, accept_response} = HydraApi.accept_logout(logout_challenge)
    redirect(conn, external: accept_response.body["redirect_to"])
  end

  def logout(_conn, _params),
    do: throw("Expected a logout challenge to be set but received none")

  ##### LOST PASSWORD #####

  def lost_password_enter_email(conn, _params) do
    render_with_client(conn, "lost-password-enter-email.html", error_message: nil)
  end

  def send_lost_password_code(conn, %{"email" => email}) do
    case get_user_with_email(email) do
      {:ok, user} -> Accounts.send_lost_password_code(user)
      # Here we do not return errors to avoid brute force of error messages
      _error -> nil
    end

    # This is an intended behavior.
    # If the email does not exists, we should not return an error to the client.
    # Otherwise it gives an information to hackers and allow brutforce
    conn
    |> put_session(:email, email)
    |> render_change_lost_password(email)
  end

  def lost_password_send_code(conn, _params),
    do: render_with_client(conn, "lost-password-enter-email.html", error_message: "Email is required")

  def change_lost_password(conn, %{"user" => %{"code" => code} = params}) do
    email = get_session(conn, :email)

    with {:ok, user} <- get_user_with_email(email),
         {:ok, _password} <- Accounts.update_user_password_with_code(user, params) do
      redirect_next_step(conn, user)
    else
      # Here we return :no_such_password_code instead of :incorrect_email
      # to avoid leaking whether an email address exists on Lenra
      {:error,
       %LenraCommon.Errors.BusinessError{
         reason: :incorrect_email
       }} ->
        render_change_lost_password(conn, email, code, BusinessError.no_such_password_code())

      {:error, %LenraCommon.Errors.BusinessError{} = error} ->
        render_change_lost_password(conn, email, code, error)

      {:error, :new_password, changeset, _done} ->
        render_change_lost_password(conn, changeset, code, nil)
    end
  end

  def change_lost_password(conn, params),
    do: cancel_login(conn, params)

  ##### EMAIL CHECK #####

  # Show the email validation form.
  def check_email_page(conn, _params) do
    # client = response.body["client"]
    render_with_client(conn, "email-token.html", error_message: nil)
  end

  # Handle the email validation form and login the user if the CGS are accepted.
  def check_email_token(conn, %{"token" => token}) do
    user_id = get_session(conn, :user_id)

    case user_id
         |> Accounts.get_user()
         |> Accounts.validate_user(token) do
      {:ok, %{updated_user: user}} ->
        redirect_next_step(conn, user)

      _error ->
        render_with_client(conn, "email-token.html", error_message: "Invalid token")
    end
  end

  def check_email_token(conn, _params),
    do: render_with_client(conn, "email-token.html", error_message: "Token is required")

  # The "create" handle the register form
  def resend_check_email_token(conn, _params) do
    user_id = get_session(conn, :user_id)

    {:ok, _any} =
      user_id
      |> Accounts.get_user()
      |> Accounts.resend_registration_code()

    json(conn, %{})
  end

  ##### CGS VALIDATION #####

  # Show the email validation form.
  def validate_cgs_page(conn, %{"lang" => lang}) do
    render_cgs_page(conn, lang)
  end

  # Show the email validation form.
  def validate_cgs_page(conn, _params) do
    render_cgs_page(conn)
  end

  # Handle the email validation form and login the user if the CGS are accepted.
  def validate_cgs(conn, %{"cgs_id" => cgs_id, "lang" => lang}) do
    user_id = get_session(conn, :user_id)

    case Legal.accept_cgs(cgs_id, user_id) do
      {:ok, _} ->
        redirect_next_step(conn, Accounts.get_user(user_id))

      _error ->
        render_cgs_page(
          conn,
          lang,
          "The validated terms and conditions are not the latest. Please try again."
        )
    end
  end
end
