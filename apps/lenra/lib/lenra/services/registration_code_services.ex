defmodule Lenra.RegistrationCodeServices do
  @moduledoc """
    The user service.
  """

  alias Lenra.{RegistrationCode, User}

  @spec delete(RegistrationCode.t()) :: any
  def delete(%RegistrationCode{} = registration_code) do
    Ecto.Multi.new()
    |> Ecto.Multi.delete(:deleted_registration_code, registration_code)
  end

  @spec registration_code_changeset(User.t()) :: Ecto.Changeset.t()
  def registration_code_changeset(%User{} = user) do
    Ecto.build_assoc(user, :registration_code)
    |> RegistrationCode.changeset(%{code: generate_code()})
  end

  def create(user) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:inserted_registration_code, RegistrationCode.new(user, generate_code()))
  end

  def check_valid(%RegistrationCode{} = registration_code, code) do
    if registration_code.code == code do
      {:ok, registration_code}
    else
      {:error, :no_such_registration_code}
    end
  end

  @chars "123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ" |> String.split("", trim: true)
  @code_length 8
  def generate_code do
    Enum.reduce(1..@code_length, [], fn _i, acc ->
      [Enum.random(@chars) | acc]
    end)
    |> Enum.join("")
  end
end
