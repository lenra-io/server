defmodule LenraServers.OpenfaasTest do
  @moduledoc """
    Test the Errors for some routes
  """
  use ExUnit.Case, async: false
  use Lenra.RepoCase

  alias Lenra.FaasStub, as: AppStub
  alias Lenra.{Openfaas, LenraApplication, Build}

  @john_doe_application %LenraApplication{
    name: "test",
    service_name: "test_service",
    color: "FFFFFF",
    icon: 1
  }

  @john_doe_build %Build{
    commit_hash: "abcdef",
    build_number: 1,
    status: "pending",
    application: @john_doe_application
  }

  @john_doe_action %ApplicationRunner.Action{
    user_id: 1,
    app_name: "StubApp",
    build_number: 1,
    action_name: "InitData",
    old_data: %{"toto" => "tata"},
    action_logs_uuid: "92846b3e-e85a-431d-9138-8b7ddaf05f66"
  }

  describe "applist" do
    setup do
      faas = AppStub.create_faas_stub()
      app = AppStub.stub_app(faas, "StubApp", 1)
      {:ok, %{app: app, faas: faas}}
    end

    test "Openfaas correctly handle ok 200 and decode data", %{app: app} do
      AppStub.stub_action_once(app, "InitData", %{"stats" => %{"listeners" => 111_111, "ui" => 111_111}})

      assert {:ok, %{"stats" => %{"listeners" => 111_111, "ui" => 111_111}}} ==
               Openfaas.run_action(@john_doe_action)
    end

    test "Openfaas correctly handle 404 not found", %{app: app} do
      AppStub.stub_action_once(app, "InitData", {:error, 404, "Not Found"})

      assert_raise(RuntimeError, "Openfaas error (404) Not Found", fn ->
        Openfaas.run_action(@john_doe_action)
      end)
    end
  end

  describe "get_app_resource" do
    test "openfaas not accessible" do
      assert {:error, %Mint.TransportError{reason: :econnrefused}} ==
               Openfaas.get_app_resource("test", 1, "download.jpeg")
    end

    test "successful for very small data" do
      faas = AppStub.create_faas_stub()
      app = AppStub.stub_app_resource(faas, "StubApp", 1)

      AppStub.stub_resource_once(app, "download.jpeg", %{})

      {:ok, res} = Openfaas.get_app_resource("StubApp", 1, "download.jpeg")

      assert Keyword.get(res, :data) == "{}"
    end
  end

  describe "deploy" do
    test "app but openfaas unreachable" do
      assert_raise(RuntimeError, "Openfaas could not be reached. It should not happen.", fn ->
        Openfaas.deploy_app(@john_doe_application.service_name, @john_doe_build.build_number)
      end)
    end

    test "app and openfaas reachable" do
      AppStub.create_faas_stub()
      |> AppStub.expect_deploy_app_once(%{"ok" => "200"})

      res = Openfaas.deploy_app(@john_doe_application.service_name, @john_doe_build.build_number)

      assert res == {:ok, 200}
    end
  end

  describe "delete" do
    test "app and openfaas reachable" do
      AppStub.create_faas_stub()
      |> AppStub.expect_delete_app_once(%{"ok" => "200"})

      res =
        Openfaas.delete_app_openfaas(
          @john_doe_application.service_name,
          @john_doe_build.build_number
        )

      assert res == {:ok, 200}
    end

    test "app but openfaas error 400" do
      AppStub.create_faas_stub()
      |> AppStub.expect_delete_app_once({:error, 400, "Bad request"})

      assert_raise(
        RuntimeError,
        "Openfaas could not delete the application. It should not happen.",
        fn ->
          Openfaas.delete_app_openfaas(
            @john_doe_application.service_name,
            @john_doe_build.build_number
          )
        end
      )
    end

    @tag capture_log: true
    test "app but openfaas error 404" do
      AppStub.create_faas_stub()
      |> AppStub.expect_delete_app_once({:error, 404, "Not found"})

      res =
        Openfaas.delete_app_openfaas(
          @john_doe_application.service_name,
          @john_doe_build.build_number
        )

      assert res == {:ok, 404}
    end
  end
end
