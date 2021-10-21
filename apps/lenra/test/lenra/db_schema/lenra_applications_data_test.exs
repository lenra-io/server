defmodule Lenra.LenraApplicationDataTest do
  use Lenra.RepoCase, async: true

  alias Lenra.{ApplicationsData, ApplicationsData, LenraApplicationServices}

  setup do
    {:ok, data: create_application()}
  end

  defp create_application do
    {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()

    params = %{
      name: "mine-sweeper",
      service_name: "mine-sweeper",
      color: "FFFFFF",
      icon: "60189"
    }

    {:ok, %{inserted_application: app}} =
      LenraApplicationServices.create(
        user.id,
        params
      )

    %{application: app, user_uuid: user.id}
  end

  describe "lenra_appliaction_data" do
    test "new/2 create applications data for user", %{
      data: %{application: application, user_uuid: _user_id}
    } do
      {:ok, inserted_app_data} = Repo.insert(ApplicationsData.new(application, %{json_data: %{test: "test"}}))

      {:ok, app_data} = Repo.fetch_by(ApplicationsData, %{id: inserted_app_data.id})

      application_id = application.id
      assert %{application_id: application_id, json_data: %{"test" => "test"}} = app_data
    end

    test "new/2 with invalid data should failed", %{
      data: %{application: application, user_uuid: _user_id}
    } do
      app_data = Repo.insert(ApplicationsData.new(application, %{data: %{test: "test"}}))
      assert {:error, %{errors: [json_data: _error_message]}} = app_data
    end
  end
end
