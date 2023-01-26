defmodule Lenra.Notifications.NotifyProvider do
  use Lenra.Schema
  import Ecto.Changeset

  alias Lenra.Notifications.NotifyProvider
  alias Lenra.Accounts.User

  @derive {Jason.Encoder,
           only: [
             :device_id,
             :endpoint,
             :system,
             :user_id
           ]}

  schema "notify_provider" do
    field(:device_id, :string)
    field(:endpoint, :string)
    field(:system, Ecto.Enum, values: [:unified_push, :fcm, :apns, :ws])
    belongs_to(:user, User)

    timestamps()
  end

  def changeset(dev_code, params \\ %{}) do
    dev_code
    |> cast(params, [:device_id, :user_id, :endpoint, :system])
    |> validate_required([:device_id, :user_id, :endpoint, :system])
    |> unique_constraint([:device_id])
    |> foreign_key_constraint(:user_id)
  end

  def new(params) do
    changeset(%NotifyProvider{}, params)
  end
end
