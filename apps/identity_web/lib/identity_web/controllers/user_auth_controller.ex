defmodule IdentityWeb.UserAuthController do
  use IdentityWeb, :controller

  alias Lenra.Accounts
  alias Lenra.Accounts.Password
  alias Lenra.Accounts.User
  alias LenraWeb.TokenHelper

  ######################
  ## Helper functions ##
  ######################

  defp get_login_request(login_challenge) do
    ORY.Hydra.get_login_request(%{login_challenge: login_challenge})
    |> ORY.Hydra.request(%{url: hydra_url()})
  end

  defp accept_login(login_challenge, subject, remember \\ false) do
    ORY.Hydra.accept_login_request(%{
      login_challenge: login_challenge,
      subject: subject,
      remember: remember,
      remember_for: 3600
    })
    |> ORY.Hydra.request(%{url: hydra_url()})
  end

  defp hydra_url do
    Application.fetch_env!(:identity_web, :hydra_url)
  end

  defp register_changeset_or_new(nil), do: Accounts.User.registration_changeset(%User{password: [%Password{}]}, %{})
  defp register_changeset_or_new(changeset), do: changeset

  #################
  ## Controllers ##
  #################

  # The "New" show the login/register form to the user if not already logged in.
  def new(conn, %{"login_challenge" => login_challenge}) do
    {:ok, response} = get_login_request(login_challenge)

    if response.body["skip"] do
      # Can do logic stuff here like update the session.
      # The user is already logged in, skip login and redirect.
      {:ok, accept_response} = accept_login(login_challenge, response.body["subject"])
      redirect(conn, external: accept_response.body["redirect_to"])
    else
      render(conn, "new.html",
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
    %{"email" => email, "password" => password, "remember_me" => remember} = user_params

    case Accounts.login_user(email, password) do
      {:ok, user} ->
        {:ok, accept_response} = accept_login(login_challenge, to_string(user.id), remember == "true")
        redirect(conn, external: accept_response.body["redirect_to"])

      _error ->
        # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
        changeset = Accounts.User.registration_changeset(%User{password: [%Password{}]}, %{})

        render(conn, "new.html",
          error_message: "Invalid email or password",
          login_challenge: login_challenge,
          changeset: register_changeset_or_new(params["user_register"])
        )
    end
  end

  def login(_conn, _),
    do: throw("No login_challenge in login form POST. It should be passed in the render.")

  # The "create" handle the register form
  def create(conn, %{"user_register" => %{"login_challenge" => login_challenge} = user_register_params}) do
    case Accounts.register_user_new(user_register_params) do
      {:ok, %{inserted_user: user}} ->
        {:ok, accept_response} = accept_login(login_challenge, to_string(user.id), false)
        redirect(conn, external: accept_response.body["redirect_to"])

      {:error, :inserted_user, %Ecto.Changeset{} = changeset, _done} ->
        render(conn, "new.html",
          error_message: nil,
          changeset: register_changeset_or_new(changeset),
          login_challenge: login_challenge
        )

      {:error, :password, changeset, _done} ->
        render(conn, "new.html",
          error_message: nil,
          changeset: register_changeset_or_new(changeset),
          login_challenge: login_challenge
        )
    end
  end

  def create(_conn, _),
    do: throw("No login_challenge in login form POST. It should be passed in the render.")
end