defmodule Lenra.OpenfaasServicesTest do
  @moduledoc """
    Test the Errors for some routes
  """
  use ExUnit.Case, async: false
  use Lenra.RepoCase

  alias Lenra.{
    Build,
    Environment,
    FaasStub,
    LenraApplication,
    OpenfaasServices
  }

  @john_doe_application %LenraApplication{
    name: "stubapp",
    color: "FFFFFF",
    icon: 1
  }

  @john_doe_build %Build{
    commit_hash: "abcdef",
    build_number: 1,
    status: "pending",
    application: @john_doe_application
  }

  @john_doe_environment %Environment{
    deployed_build: @john_doe_build
  }

  describe "run_listener" do
    setup do
      faas = FaasStub.create_faas_stub()
      app = FaasStub.stub_app(faas, @john_doe_application.service_name, 1)
      {:ok, %{app: app, faas: faas}}
    end

    test "Openfaas correctly handle ok 200 and decode data", %{app: app} do
      FaasStub.stub_action_once(app, "InitData", %{"data" => %{"foo" => "bar"}})

      assert {:ok, %{"foo" => "bar"}} ==
               OpenfaasServices.run_listener(
                 @john_doe_application,
                 @john_doe_environment,
                 "InitData",
                 %{},
                 %{},
                 %{}
               )
    end

    test "Openfaas correctly handle 404 not found", %{app: app} do
      FaasStub.stub_action_once(app, "InitData", {:error, 404, "Not Found"})

      assert_raise(RuntimeError, "Openfaas error (404) Not Found", fn ->
        OpenfaasServices.run_listener(
          @john_doe_application,
          @john_doe_environment,
          "InitData",
          %{},
          %{},
          %{}
        )
      end)
    end
  end

  describe "get_app_resource" do
    test "openfaas not accessible" do
      assert {:error, %Mint.TransportError{reason: :econnrefused}} ==
               OpenfaasServices.get_app_resource("invalid", 1, "download.jpeg")
    end

    test "successful for very small data" do
      faas = FaasStub.create_faas_stub()
      app = FaasStub.stub_app_resource(faas, @john_doe_application.service_name, 1)

      FaasStub.stub_resource_once(app, "download.jpeg", %{})

      {:ok, res} = OpenfaasServices.get_app_resource(@john_doe_application.service_name, 1, "download.jpeg")

      assert Keyword.get(res, :data) == "{}"
    end
  end

  describe "deploy" do
    test "app but openfaas unreachable" do
      assert_raise(RuntimeError, "Openfaas could not be reached. It should not happen.", fn ->
        OpenfaasServices.deploy_app(
          @john_doe_application.service_name,
          @john_doe_build.build_number
        )
      end)
    end

    test "app and openfaas reachable" do
      FaasStub.create_faas_stub()
      |> FaasStub.expect_deploy_app_once(%{"ok" => "200"})

      res =
        OpenfaasServices.deploy_app(
          @john_doe_application.service_name,
          @john_doe_build.build_number
        )

      assert res == {:ok, 200}
    end
  end

  describe "delete" do
    test "app and openfaas reachable" do
      FaasStub.create_faas_stub()
      |> FaasStub.expect_delete_app_once(%{"ok" => "200"})

      res =
        OpenfaasServices.delete_app_openfaas(
          @john_doe_application.service_name,
          @john_doe_build.build_number
        )

      assert res == {:ok, 200}
    end

    test "app but openfaas error 400" do
      FaasStub.create_faas_stub()
      |> FaasStub.expect_delete_app_once({:error, 400, "Bad request"})

      assert_raise(
        RuntimeError,
        "Openfaas could not delete the application. It should not happen.",
        fn ->
          OpenfaasServices.delete_app_openfaas(
            @john_doe_application.service_name,
            @john_doe_build.build_number
          )
        end
      )
    end

    @tag capture_log: true
    test "app but openfaas error 404" do
      FaasStub.create_faas_stub()
      |> FaasStub.expect_delete_app_once({:error, 404, "Not found"})

      res =
        OpenfaasServices.delete_app_openfaas(
          @john_doe_application.service_name,
          @john_doe_build.build_number
        )

      assert res == {:ok, 404}
    end
  end
end