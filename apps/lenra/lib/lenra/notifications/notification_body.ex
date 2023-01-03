defmodule Lenra.Notifications.NotificationBody do
  use Lenra.Schema

  embedded_schema do
    field(:message, :string)
    field(:title, :string)
    field(:priority, Ecto.Enum, values: [min: 1, low: 2, normal: 3, high: 4, max: 5])
    field(:tags, :string)
    field(:attach, :string)
    field(:actions, :string)
    field(:email, :string)
    field(:click, :string)
    field(:at, :string)
  end
end
