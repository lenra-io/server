defmodule ApplicationRunner.RepoCase do
  @moduledoc false

  use ExUnit.CaseTemplate
  alias Ecto.Adapters.SQL.Sandbox

  using do
    quote do
      use ExUnit.Case, async: false
      alias ApplicationRunner.Repo

      import Ecto
      import Ecto.Query
      import ApplicationRunner.RepoCase
      import Phoenix.ConnTest
      import Plug.Conn

      alias ApplicationRunner.Router.Helpers, as: Routes

      # and any other stuff
    end
  end

  setup tags do
    :ok = Sandbox.checkout(ApplicationRunner.Repo)

    unless tags[:async] do
      Sandbox.mode(ApplicationRunner.Repo, {:shared, self()})
    end
  end
end
