defmodule LenraServers.SocketAppMeasurementServicesTest do
  use Lenra.RepoCase, async: true

  alias Lenra.{SocketAppMeasurement, SocketAppMeasurementServices, LenraApplication, AppUserSessionService}

  @moduledoc """
    Test the client app measurement services
  """
  setup do
    {:ok, app_session: create_app_user_session()}
  end

  defp create_app_user_session do
    app_session_uuid = Ecto.UUID.generate()

    {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()

    {:ok, app} =
      Repo.insert(
        LenraApplication.new(user.id, %{name: "test", service_name: Ecto.UUID.generate(), color: "FF0000", icon: 0xEB09})
      )

    AppUserSessionService.create(user.id, %{
      service_name: app.service_name,
      uuid: app_session_uuid,
      build_number: 1
    })

    app_session_uuid
  end

  describe "get" do
    test "measurement successfully", %{app_session: app_session} do
      SocketAppMeasurementServices.create(%{
        duration: 1,
        app_user_session_uuid: app_session
      })

      tmp_measurement = Enum.at(Repo.all(SocketAppMeasurement), 0)

      measurement = SocketAppMeasurementServices.get(tmp_measurement.id)

      assert measurement == tmp_measurement

      assert %SocketAppMeasurement{duration: 1} = measurement

      assert measurement.app_user_session_uuid == app_session
    end

    test "measurement which does not exist", %{app_session: _app_session} do
      assert nil == SocketAppMeasurementServices.get(0)
    end
  end

  describe "get_by" do
    test "measurement succesfully", %{app_session: app_session} do
      SocketAppMeasurementServices.create(%{
        duration: 1,
        app_user_session_uuid: app_session
      })

      tmp_measurement = Enum.at(Repo.all(SocketAppMeasurement), 0)
      measurement = SocketAppMeasurementServices.get_by(duration: 1)

      assert tmp_measurement == measurement

      assert %SocketAppMeasurement{duration: 1} = measurement

      assert measurement.app_user_session_uuid == app_session
    end

    test "measurement which does not exist", %{app_session: _app_session} do
      assert nil == SocketAppMeasurementServices.get_by(duration: 1)
    end
  end

  describe "create" do
    test "measurement successfully", %{app_session: app_session} do
      SocketAppMeasurementServices.create(%{
        duration: 1,
        app_user_session_uuid: app_session
      })

      measurement = Enum.at(Repo.all(SocketAppMeasurement), 0)

      assert %SocketAppMeasurement{duration: 1} = measurement

      assert measurement.app_user_session_uuid == app_session
    end
  end
end
