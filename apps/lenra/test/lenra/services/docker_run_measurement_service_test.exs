defmodule Lenra.DockerRunMeasurementServicesTest do
  use Lenra.RepoCase, async: true

  alias Lenra.{
    DockerRunMeasurement,
    DockerRunMeasurementServices,
    LenraApplication,
    AppUserSessionService,
    ActionLogsService
  }

  setup do
    {:ok, action_logs_uuid: create_app_user_session()}
  end

  defp create_app_user_session do
    app_session_uuid = Ecto.UUID.generate()
    action_logs_uuid = Ecto.UUID.generate()
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

    ActionLogsService.create(%{uuid: action_logs_uuid, app_user_session_uuid: app_session_uuid, action: "Test"})

    action_logs_uuid
  end

  describe "DockerRunMeasurementServices.create_1/1" do
    test "create successfully if parameters valid", %{action_logs_uuid: action_logs_uuid} do
      DockerRunMeasurementServices.create(%{
        action_logs_uuid: action_logs_uuid,
        ui_duration: 111_111,
        listeners_duration: 111_111
      })

      tmp_measurement = Enum.at(Repo.all(DockerRunMeasurement), 0)

      assert tmp_measurement.action_logs_uuid == action_logs_uuid
    end

    test "create failure if parameters invalid", %{action_logs_uuid: action_logs_uuid} do
      DockerRunMeasurementServices.create(%{
        action_logs_uuid: action_logs_uuid,
        listeners_duration: 111_111
      })

      tmp_measurement = Enum.at(Repo.all(DockerRunMeasurement), 0)

      assert is_nil(tmp_measurement) == true
    end
  end

  describe "DockerRunMeasurementServices.get_1/1" do
    test "should return user if the id is valid", %{action_logs_uuid: action_logs_uuid} do
      DockerRunMeasurementServices.create(%{
        action_logs_uuid: action_logs_uuid,
        ui_duration: 111_111,
        listeners_duration: 111_111
      })

      tmp_measurement = Enum.at(Repo.all(DockerRunMeasurement), 0)

      measurement = DockerRunMeasurementServices.get(tmp_measurement.id)

      assert measurement.action_logs_uuid == action_logs_uuid
      assert measurement == tmp_measurement
    end

    test "should return nil if the id is invalid", %{action_logs_uuid: action_logs_uuid} do
      DockerRunMeasurementServices.create(%{
        action_logs_uuid: action_logs_uuid,
        ui_duration: 111_111,
        listeners_duration: 111_111
      })

      tmp_measurement = Enum.at(Repo.all(DockerRunMeasurement), 0)

      measurement = DockerRunMeasurementServices.get(tmp_measurement.id + 1)

      assert is_nil(measurement) == true
    end
  end

  describe "DockerRunMeasurementServices.get_by_1/1" do
    test "should return user if clauses is valid", %{action_logs_uuid: action_logs_uuid} do
      DockerRunMeasurementServices.create(%{
        action_logs_uuid: action_logs_uuid,
        ui_duration: 111_111,
        listeners_duration: 111_111
      })

      measurement = DockerRunMeasurementServices.get_by(%{action_logs_uuid: action_logs_uuid})

      assert measurement.action_logs_uuid == action_logs_uuid
    end

    test "should return nil if clauses is invalid", %{action_logs_uuid: action_logs_uuid} do
      DockerRunMeasurementServices.create(%{
        action_logs_uuid: action_logs_uuid,
        ui_duration: 111_111,
        listeners_duration: 111_111
      })

      measurement = DockerRunMeasurementServices.get_by(%{action_logs_uuid: Ecto.UUID.generate()})

      assert is_nil(measurement) == true
    end
  end
end
