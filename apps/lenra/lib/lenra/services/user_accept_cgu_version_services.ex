defmodule Lenra.UserAcceptCguVersionServices do
  @moduledoc """
    The cgu service.
  """

  alias Lenra.{Cgu, User, UserAcceptCguVersion}

  def acceptCguVersion(%User{} = user, %Cgu{} = cgu) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(
      :inserted_user_accept_cgu_version,
      UserAcceptCguVersion.new(%{user_id: user.id, cgu_id: cgu.id})
    )
  end
end
