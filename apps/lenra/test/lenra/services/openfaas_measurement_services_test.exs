defmodule Lenra.OpenfaasMeasurementServicesTest do
  @moduledoc """
    Test the openfaas measurement services
  """
  use Lenra.RepoCase, async: true

  alias Lenra.{
    ActionLogsService,
    AppUserSessionService,
    LenraApplication,
    OpenfaasRunActionMeasurement,
    OpenfaasRunActionMeasurementServices
  }

  setup do
    {:ok, action_logs_uuid: create_app_user_session()}
  end

  defp create_app_user_session do
    app_session_uuid = Ecto.UUID.generate()
    action_logs_uuid = Ecto.UUID.generate()
    {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()

    {:ok, app} =
      Repo.insert(LenraApplication.new(user.id, %{name: "test", color: "FF0000", icon: 0xEB09}))

    AppUserSessionService.create(user.id, %{
      service_name: app.service_name,
      uuid: app_session_uuid,
      build_number: 1
    })

    ActionLogsService.create(%{
      uuid: action_logs_uuid,
      app_user_session_uuid: app_session_uuid,
      action: "Test"
    })

    action_logs_uuid
  end

  describe "get" do
    test "measurement successfully", %{action_logs_uuid: action_logs_uuid} do
      OpenfaasRunActionMeasurementServices.create(%{
        action_logs_uuid: action_logs_uuid,
        duration: 1
      })

      tmp_measurement = Enum.at(Repo.all(OpenfaasRunActionMeasurement), 0)

      measurement = OpenfaasRunActionMeasurementServices.get(tmp_measurement.id)

      assert measurement == tmp_measurement

      assert %OpenfaasRunActionMeasurement{duration: 1} = measurement

      assert measurement.action_logs_uuid == action_logs_uuid
    end

    test "measurement which does not exist", %{action_logs_uuid: _action_logs_uuid} do
      assert nil == OpenfaasRunActionMeasurementServices.get(0)
    end
  end

  describe "get_by" do
    test "measurement succesfully", %{action_logs_uuid: action_logs_uuid} do
      OpenfaasRunActionMeasurementServices.create(%{
        action_logs_uuid: action_logs_uuid,
        duration: 1
      })

      tmp_measurement = Enum.at(Repo.all(OpenfaasRunActionMeasurement), 0)
      measurement = OpenfaasRunActionMeasurementServices.get_by(duration: 1)

      assert tmp_measurement == measurement

      assert %OpenfaasRunActionMeasurement{duration: 1} = measurement

      assert measurement.action_logs_uuid == action_logs_uuid
    end

    test "measurement which does not exist", %{action_logs_uuid: _action_logs_uuid} do
      assert nil == OpenfaasRunActionMeasurementServices.get_by(duration: 1)
    end
  end

  describe "create" do
    test "measurement successfully", %{action_logs_uuid: action_logs_uuid} do
      OpenfaasRunActionMeasurementServices.create(%{
        action_logs_uuid: action_logs_uuid,
        duration: 1
      })

      measurement = Enum.at(Repo.all(OpenfaasRunActionMeasurement), 0)

      assert %OpenfaasRunActionMeasurement{duration: 1} = measurement

      assert measurement.action_logs_uuid == action_logs_uuid
    end
  end
end
