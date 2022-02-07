defmodule Lenra.ActionLogsServiceTest do
  use Lenra.RepoCase, async: true
  alias Lenra.{ActionLogs, ActionLogsService, AppUserSessionService, LenraApplication}

  setup do
    {:ok, app_session: create_app_user_session()}
  end

  defp create_app_user_session do
    app_session_uuid = Ecto.UUID.generate()
    {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()
    {:ok, app} = create_app(user.id)

    AppUserSessionService.create(user.id, %{
      service_name: app.service_name,
      uuid: app_session_uuid,
      build_number: 1
    })

    app_session_uuid
  end

  defp create_app(user_id) do
    Repo.insert(
      LenraApplication.new(user_id, %{name: "test", service_name: Ecto.UUID.generate(), color: "FF0000", icon: 0xEB09})
    )
  end

  describe "ActionLogsService.create_1/1" do
    test "create successfully if parameters valid", %{app_session: app_session} do
      action_uuid = Ecto.UUID.generate()

      ActionLogsService.create(%{uuid: action_uuid, app_user_session_uuid: app_session, action: "Test"})

      tmp_measurement = Enum.at(Repo.all(ActionLogs), 0)

      assert tmp_measurement.uuid == action_uuid
    end

    test "create failure if parameters invalid" do
      action_uuid = Ecto.UUID.generate()
      ActionLogsService.create(%{uuid: action_uuid, app_user_session_uuid: action_uuid, action: "Test"})

      tmp_measurement = Enum.at(Repo.all(ActionLogs), 0)

      assert is_nil(tmp_measurement) == true
    end
  end

  describe "ActionLogsService.get_by_1/1" do
    test "should return user if clauses is valid", %{app_session: app_session} do
      action_uuid = Ecto.UUID.generate()

      ActionLogsService.create(%{uuid: action_uuid, app_user_session_uuid: app_session, action: "Test"})

      measurement = ActionLogsService.get_by(%{uuid: action_uuid})

      assert measurement.uuid == action_uuid
    end

    test "should return nil if clauses is invalid", %{app_session: app_session} do
      action_uuid = Ecto.UUID.generate()

      ActionLogsService.create(%{uuid: action_uuid, app_user_session_uuid: app_session, action: "Test"})

      measurement = ActionLogsService.get_by(%{uuid: app_session})

      assert is_nil(measurement) == true
    end
  end
end
