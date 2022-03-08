defmodule Lenra.UserAcceptCguVersionServices do
  @moduledoc """
    The cgu service.
  """

  alias Lenra.{Cgu, Repo, User, UserAcceptCguVersion}

  def accept_cgu_version(%User{} = user, %Cgu{} = cgu) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(
      :inserted_user_accept_cgu_version,
      UserAcceptCguVersion.new(%{cgu_id: cgu.id, user_id: user.id})
    )
    |> Repo.transaction()
  end
end
