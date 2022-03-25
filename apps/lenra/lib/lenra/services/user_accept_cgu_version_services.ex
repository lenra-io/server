defmodule Lenra.UserAcceptCguVersionServices do
  @moduledoc """
    The user accept cgu version service.
  """

  alias Lenra.{Cgu, Repo, User, UserAcceptCguVersion}

  def create(%User{} = user, %Cgu{} = cgu) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(
      :inserted_user_accept_cgu_version,
      UserAcceptCguVersion.new(%{cgu_id: cgu.id, user_id: user.id})
    )
    |> Repo.transaction()
  end
end
