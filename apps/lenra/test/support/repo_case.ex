defmodule Lenra.RepoCase do
  @moduledoc """
    Setup the repo case test. Use it in new module test like that :
      defmodule Lenra.UserTest do
        use Lenra.RepoCase
      end
  """
  use ExUnit.CaseTemplate
  alias Ecto.Adapters.SQL.Sandbox

  using do
    quote do
      alias Lenra.Repo

      import Ecto
      import Ecto.Query
      import Lenra.RepoCase

      import UserTestHelper

      # and any other stuff
    end
  end

  setup tags do
    :ok = Sandbox.checkout(Lenra.Repo)

    unless tags[:async] do
      Sandbox.mode(Lenra.Repo, {:shared, self()})
    end

    resp = %{}
    resp = register_user(tags, resp)

    resp
  end

  defp register_user(tags, resp) do
    if tags[:register_user] do
      {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()
      Map.put(resp, :user, user)
    else
      resp
    end
  end
end
