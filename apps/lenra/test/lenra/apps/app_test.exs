defmodule Lenra.Apps.AppTest do
  use Lenra.RepoCase, async: true

  alias Lenra.Apps.App
  alias Lenra.AppUserSession

  @valide_data %{name: "Test", color: "FF0000", icon: 1111, repository: "repository"}
  @invalide_data %{name: nil, color: nil, icon: nil, repository: nil}

  describe "lenra_appliaction" do
    test "new/2 with valid data creates a lenra_application" do
      assert %{changes: app, valid?: true} = App.new(1, @valide_data)
      assert app.name == @valide_data.name
      assert app.color == @valide_data.color
      assert app.icon == @valide_data.icon
      assert app.repository == @valide_data.repository
    end

    test "new/2 with invalid data creates a lenra_application" do
      assert %{changes: _app, valid?: false} = App.new(1, @invalide_data)
    end

    test "attached to app_user_session should succed" do
      # Create user
      {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()

      # Create and insert lenra_application
      app = App.new(user.id, @valide_data)
      {:ok, %App{} = inserted_app} = Repo.insert(app)

      # Test create and insert app_user_session
      session_uuid = Ecto.UUID.generate()

      session =
        AppUserSession.new(%{
          uuid: session_uuid,
          user_id: user.id,
          application_id: inserted_app.id,
          build_number: 1
        })

      assert %{valid?: true} = session

      {:ok, %AppUserSession{} = inserted_session} = Repo.insert(session)
      loaded_inserted_session = Repo.preload(inserted_session, :application)
      assert loaded_inserted_session.application == inserted_app

      [head | _tail] = Repo.all(Ecto.assoc(inserted_app, :app_user_session))
      assert head == inserted_session
    end
  end
end
