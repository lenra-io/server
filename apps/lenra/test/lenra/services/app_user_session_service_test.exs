defmodule Lenra.AppUserSessionServiceTest do
  use Lenra.RepoCase, async: true
  alias Lenra.{AppUserSessionService, AppUserSession, LenraApplication}

  setup do
    {:ok, user_id: create_user()}
  end

  defp create_user do
    {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()
    {:ok, _app} = create_app(user.id)

    user.id
  end

  defp create_app(user_id) do
    Repo.insert(LenraApplication.new(user_id, %{name: "test", service_name: "test", color: "FF0000", icon: 0xEB09}))
  end

  describe "AppUserSessionService.create_1/1" do
    test "create successfully if parameters valid", %{user_id: user_id} do
      app_user_session_uuid = Ecto.UUID.generate()

      AppUserSessionService.create(user_id, %{uuid: app_user_session_uuid, app_name: "test", build_number: 1})

      tmp_measurement = Enum.at(Repo.all(AppUserSession), 0)

      assert tmp_measurement.uuid == app_user_session_uuid
    end

    test "create failure if parameters invalid", %{user_id: user_id} do
      app_user_session_uuid = Ecto.UUID.generate()

      AppUserSessionService.create(user_id, %{uuid: app_user_session_uuid, app_name: "app", build_number: 1})

      tmp_measurement = Enum.at(Repo.all(AppUserSession), 0)

      assert is_nil(tmp_measurement) == true
    end
  end

  describe "AppUserSessionService.get_by_1/1" do
    test "should return AppUserSession if clauses is valid", %{user_id: user_id} do
      app_user_session_uuid = Ecto.UUID.generate()

      AppUserSessionService.create(user_id, %{uuid: app_user_session_uuid, app_name: "test", build_number: 1})

      measurement = AppUserSessionService.get_by(%{uuid: app_user_session_uuid})

      assert measurement.uuid == app_user_session_uuid
    end

    test "should return nil if clauses is invalid", %{user_id: user_id} do
      app_user_session_uuid = Ecto.UUID.generate()

      AppUserSessionService.create(user_id, %{uuid: app_user_session_uuid, app_name: "test", build_number: 1})

      measurement = AppUserSessionService.get_by(%{uuid: Ecto.UUID.generate()})

      assert is_nil(measurement) == true
    end
  end
end
