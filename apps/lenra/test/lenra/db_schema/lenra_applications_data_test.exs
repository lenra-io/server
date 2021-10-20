defmodule Lenra.LenraApplicationDataTest do
  use Lenra.RepoCase, async: true

  alias Lenra.{ApplicationsData, ApplicationsData, ApplicationsUsersData, LenraApplicationServices}

  setup do
    {:ok, data: create_application()}
  end

  defp create_application() do
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
      {:ok, appli} = Repo.insert(ApplicationsData.new(application, %{json_data: %{test: "test"}}))

      {:ok, app} = Repo.fetch_by(ApplicationsData, %{id: appli.id})

      application_id = application.id
      assert %{application_id: application_id, json_data: %{"test" => "test"}} = app
    end
  end
end
