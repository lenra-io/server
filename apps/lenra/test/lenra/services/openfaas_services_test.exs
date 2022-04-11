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
      assert {:error, :openfass_not_recheable} ==
               OpenfaasServices.deploy_app(
                 @john_doe_application.service_name,
                 @john_doe_build.build_number
               )
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

      assert {:error, :openfaas_delete_error} ==
               OpenfaasServices.delete_app_openfaas(
                 @john_doe_application.service_name,
                 @john_doe_build.build_number
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

      assert res == {:error, :openfaas_delete_error}
    end
  end

  describe "fetch manifest" do
    @tag :register_user
    test "should return error if app not deployed", %{user: user} do
      {:ok, app} = Repo.insert(LenraApplication.new(user.id, %{name: "stubapp", color: "FFFFFF", icon: 1}))

      assert {:error, :environement_not_build} ==
               OpenfaasServices.fetch_manifest(app, %Environment{
                 deployed_build: nil
               })
    end
  end
end
