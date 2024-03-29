defmodule Lenra.Accounts do
  @moduledoc """
    Lenra.Accounts is the context that handle the user account with :
    - Register the user
    - Login the user
    - Validate the user with registration and/or dev codes
    - Handle the user password (reset and change)
  """

  import Ecto.Query

  alias Lenra.{EmailWorker, Repo}
  alias Lenra.Accounts.{LostPasswordCode, Password, RegistrationCode, User}
  alias Lenra.Errors.BusinessError

  @doc """
    Register a new user, save him to the database. The email must be unique. The password is hashed before inserted to the database.
  """
  def register_user_new(params, role \\ nil) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:inserted_user, User.new_with_password(params, role))
    |> Ecto.Multi.insert(:inserted_registration_code, fn %{inserted_user: %User{} = user} ->
      registration_code_changeset(user)
    end)
    |> Ecto.Multi.run(:add_event, fn
      _repo, %{inserted_registration_code: registration_code, inserted_user: user} ->
        EmailWorker.add_email_verification_event(user, registration_code.code)
    end)
    |> Repo.transaction()
  end

  def register_user(params, role \\ nil) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:inserted_user, User.new(params, role))
    |> Ecto.Multi.insert(:password, fn %{inserted_user: %User{} = user} ->
      Password.new(user, params)
    end)
    |> Ecto.Multi.insert(:inserted_registration_code, fn %{inserted_user: %User{} = user} ->
      registration_code_changeset(user)
    end)
    |> Ecto.Multi.run(:add_event, fn
      _repo, %{inserted_registration_code: registration_code, inserted_user: user} ->
        EmailWorker.add_email_verification_event(user, registration_code.code)
    end)
    |> Repo.transaction()
  end

  def resend_registration_code(user) do
    loaded_user = Repo.preload(user, :registration_code)

    Ecto.Multi.new()
    |> Ecto.Multi.delete(:deleted_registration_code, loaded_user.registration_code)
    |> Ecto.Multi.insert(:inserted_registration_code, fn _params ->
      registration_code_changeset(user)
    end)
    |> Ecto.Multi.run(:add_event, fn
      _repo, %{inserted_registration_code: registration_code} ->
        EmailWorker.add_email_verification_event(user, registration_code.code)
    end)
    |> Repo.transaction()
  end

  defp registration_code_changeset(%User{} = user) do
    user
    |> Ecto.build_assoc(:registration_code)
    |> RegistrationCode.changeset(%{code: generate_code()})
  end

  def get_user(id) do
    Repo.get(User, id)
  end

  def fetch_user_by(fields) do
    Repo.fetch_by(User, fields)
  end

  def update_user(user, params) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:updated_user, User.update(user, params))
  end

  def validate_user(user, code) do
    with loaded_user <- Repo.preload(user, :registration_code),
         true <- loaded_user.registration_code.code == code do
      Ecto.Multi.new()
      |> Ecto.Multi.delete(:deleted_registration_code, loaded_user.registration_code)
      |> Ecto.Multi.update(:updated_user, User.change_role(loaded_user, :user))
      |> Repo.transaction()
    else
      false -> BusinessError.no_such_registration_code_tuple()
      err -> err
    end
  end

  @spec validate_dev(any) :: any
  def validate_dev(user) do
    with :ok <-
           check_simple_user(user) do
      Ecto.Multi.new()
      |> Ecto.Multi.update(:updated_user, User.change_role(user, :dev))
      |> Repo.transaction()
    end
  end

  # Unused function
  # defp check_is_uuid(code) do
  #   case Ecto.UUID.dump(code) do
  #     :error -> BusinessError.invalid_uuid_tuple()
  #     {:ok, _} -> :ok
  #   end
  # end

  defp check_simple_user(%User{role: role}) when role in [:user, :unverified_user], do: :ok
  defp check_simple_user(_user), do: BusinessError.already_dev_tuple()

  @doc """
    check if the user exists in the database and compare the hashed password.
    Returns {:ok, user} if the email exists and password is correct.
    Otherwise, returns {:error, :incorrect_email_or_password}
  """
  @spec login_user(binary(), binary()) ::
          {:ok, User.t()} | {:error, LenraCommon.Errors.BusinessError.t()}
  def login_user(email, password) do
    User
    |> Repo.get_by(email: String.downcase(email))
    |> check_password(password)
  end

  defp check_password(%User{} = user, password) do
    user = Repo.preload(user, [password: from(p in Password, order_by: [desc: p.id])], force: true)

    user_password = hd(user.password)

    case Argon2.verify_pass(password, user_password.password) do
      false -> BusinessError.incorrect_email_or_password_tuple()
      true -> {:ok, user}
    end
  end

  @argon2_fake_password "$argon2id$v=19$m=32768,t=8,p=4$DkM5iCbAuzzym9LcjP0z1A$X1jXSmoDGEPLKDnAQsoWWAmnOltYpMutJnokCWLz37g"
  defp check_password(_user, password) do
    # Avoid time-based hacking technique to check if email exist
    Argon2.verify_pass(password, @argon2_fake_password)
    BusinessError.incorrect_email_or_password_tuple()
  end

  #######################
  ## PASSWORD SERVICES ##
  #######################

  @doc """
    Create a new password.
  """

  def update_user_password(
        user,
        %{"old_password" => old_password, "password" => password} = params
      ) do
    with {:ok, _user} <- check_password(user, old_password),
         :ok <- check_old_password(user, password) do
      Repo.insert(Password.new(user, params))
    end
  end

  def update_user_password_with_code(
        %User{} = user,
        %{"password" => password, "code" => code} = params
      ) do
    with {:ok, password_code} <- check_lost_password_code_valid(user, code),
         :ok <- check_old_password(user, password) do
      Ecto.Multi.new()
      |> Ecto.Multi.insert(:new_password, Password.new(user, params))
      |> Ecto.Multi.delete(:delete_password_code, password_code)
      |> Repo.transaction()
    end
  end

  defp check_lost_password_code_valid(%User{} = user, code) do
    user = Repo.preload(user, [:password_code])

    with true <- not is_nil(user.password_code),
         true <- user.password_code.code == code,
         true <- date_difference(user.password_code) do
      {:ok, user.password_code}
    else
      false -> BusinessError.no_such_password_code_tuple()
    end
  end

  defp check_old_password(user, password) do
    user = Repo.preload(user, password: from(p in Password, order_by: [desc: p.id], limit: 3))

    user.password
    |> Enum.any?(fn x ->
      Argon2.verify_pass(password, x.password)
    end)
    |> case do
      true -> BusinessError.password_already_used_tuple()
      false -> :ok
    end
  end

  @doc """
    Create a new password_code, save him to the database and send him to user by email.
  """
  def send_lost_password_code(%User{} = user) do
    code = generate_code()

    Ecto.Multi.new()
    |> Ecto.Multi.insert(
      :password_code,
      LostPasswordCode.new(user, code),
      conflict_target: :user_id,
      on_conflict: {:replace, [:code, :updated_at]}
    )
    |> Ecto.Multi.run(:add_password_event, fn _repo,
                                              %{
                                                password_code: %LostPasswordCode{} = password_code
                                              } ->
      add_password_events(password_code, user)
    end)
    |> Repo.transaction()
  end

  defp add_password_events(password_code, user) do
    EmailWorker.add_email_password_lost_event(user, password_code.code)
  end

  @validity_time 3600
  defp date_difference(password_code) do
    if NaiveDateTime.diff(NaiveDateTime.utc_now(), password_code.updated_at) <= @validity_time and
         NaiveDateTime.diff(NaiveDateTime.utc_now(), password_code.updated_at) >= 0 do
      true
    else
      false
    end
  end

  @chars String.split("123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ", "", trim: true)
  @code_length 8
  defp generate_code do
    1..@code_length
    |> Enum.reduce([], fn _i, acc -> [Enum.random(@chars) | acc] end)
    |> Enum.join("")
  end
end
