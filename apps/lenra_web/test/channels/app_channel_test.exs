defmodule LenraWeb.AppChannelTest do
  @moduledoc """
    Test the `LenraWeb.AppChannel` module
  """
  use LenraWeb.ChannelCase, async: false
  #   alias ApplicationRunner.ListenersCache

  #   alias ApplicationRunner.JsonStorage.Datastore
  # alias Lenra.Repo
  # alias Lenra.Apps.{
  #   App,
  #   MainEnv,
  #   Environment
  # }

  alias LenraWeb.UserSocket

  # @build_number 1
  # @listener_name "HiBob"
  # @listener_code Crypto.hash({@listener_name, %{}})

  # @manifest %{"manifest" => %{"rootWidget" => "test"}}

  # @data %{"data" => %{"user" => %{"name" => "World"}}}
  # @data2 %{"data" => %{"user" => %{"name" => "Bob"}}}

  # @textfield %{
  #   "type" => "textfield",
  #   "value" => "Hello World",
  #   "onChanged" => %{"action" => @listener_name}
  # }

  # @textfield2 %{
  #   "type" => "textfield",
  #   "value" => "Hello Bob",
  #   "onChanged" => %{"action" => @listener_name}
  # }

  # @transformed_textfield %{
  #   "type" => "textfield",
  #   "value" => "Hello World",
  #   "onChanged" => %{"code" => @listener_code}
  # }

  # @widget %{"widget" => %{"type" => "flex", "children" => [@textfield]}}
  # @widget2 %{"widget" => %{"type" => "flex", "children" => [@textfield2]}}

  # @expected_ui %{"root" => %{"type" => "flex", "children" => [@transformed_textfield]}}
  # @expected_patch_ui %{
  #   "patch" => [%{"op" => "replace", "path" => "/root/children/0/value", "value" => "Hello Bob"}]
  # }

  setup do
    {:ok, %{inserted_user: user}} = register_john_doe()
    socket = socket(UserSocket, "socket_id", %{user: user})

    %{socket: socket, user: user}
  end

  test "No app called, should return an error", %{socket: socket} do
    res = my_subscribe_and_join(socket)

    assert {:error, %{reason: [%{code: 21, message: "No application found for the current link."}]}} ==
             res

    refute_push("ui", _)
  end

  # test "Base use case with simple app", %{socket: socket, user: user} do
  #   # owstub
  #   # |> FaasStub.expect_deploy_app_once(%{"ok" => "200"})

  #   Ecto.Multi.new()
  #   |> Ecto.Multi.insert(
  #     :inserted_application,
  #     App.new(user.id, %{
  #       name: "Counter",
  #       color: "FFFFFF",
  #       icon: "60189"
  #     })
  #   )
  #   |> Ecto.Multi.insert(:inserted_env, fn %{inserted_application: app} ->
  #     Environment.new(app.id, user.id, nil, %{name: "live", is_ephemeral: false, is_public: false})
  #   end)
  #   |> Ecto.Multi.insert(:inserted_datastore, fn %{inserted_env: env} ->
  #     Datastore.new(env.id, %{"name" => "_users"})
  #   end)
  #   |> Ecto.Multi.insert(:inserted_build, fn %{inserted_application: app} ->
  #     Build.new(user.id, app.id, @build_number, %{status: :success})
  #   end)
  #   |> Ecto.Multi.insert(:application_main_env, fn %{inserted_application: app, inserted_env: env} ->
  #     ApplicationMainEnv.new(app.id, env.id)
  #   end)
  #   |> Ecto.Multi.update(:updated_env, fn %{inserted_env: env, inserted_build: build} ->
  #     Ecto.Changeset.change(env, deployed_build_id: build.id)
  #   end)
  #   |> Ecto.Multi.insert(:inserted_deployment, fn %{
  #                                                   inserted_application: app,
  #                                                   inserted_env: env,
  #                                                   inserted_build: build
  #                                                 } ->
  #     Deployment.new(app.id, env.id, build.id, user.id, %{})
  #   end)
  #   |> Repo.transaction()

  #   app = Repo.get_by(App, name: "Counter")

  #   owstub =
  #     FaasStub.create_faas_stub()
  #     |> FaasStub.stub_app(app.service_name, @build_number)

  #   # Base use case. Call InitData then MainUI then call the listener
  #   # and the next MainUI should not be called but taken from cache instead
  #   owstub
  #   |> FaasStub.stub_request_once(@manifest)
  #   |> FaasStub.stub_request_once(@data)
  #   |> FaasStub.stub_request_once(@widget)
  #   |> FaasStub.stub_request_once(@data2)
  #   |> FaasStub.stub_request_once(@widget2)

  #   # Join the channel
  #   {:ok, _reply, socket} = my_subscribe_and_join(socket, %{"app" => app.service_name})

  #   # Check that the correct data is stored into the socket
  #   assert %{
  #            user: ^user
  #          } = socket.assigns

  #   # Check that we receive a "ui" event with the final UI

  #   assert_push("ui", @expected_ui)

  #   # We simulate an event from the UI
  #   push(socket, "run", %{"code" => @listener_code})

  #   # Check that we receive a "patchUi" event with corresponding patch
  #   assert_push("patchUi", @expected_patch_ui)

  #   Process.unlink(socket.channel_pid)
  #   ref = leave(socket)

  #   assert_reply(ref, :ok)

  #   # Waiting for monitor to write measurements in db
  #   :timer.sleep(500)
  # end

  # test "Join app channel with unauthorized user", %{socket: _socket, user: user} do
  #   Ecto.Multi.new()
  #   |> Ecto.Multi.insert(
  #     :inserted_application,
  #     App.new(user.id, %{
  #       name: "Counter",
  #       color: "FFFFFF",
  #       icon: "60189"
  #     })
  #   )
  #   |> Ecto.Multi.insert(:inserted_env, fn %{inserted_application: app} ->
  #     Environment.new(app.id, user.id, nil, %{name: "live", is_ephemeral: false, is_public: false})
  #   end)
  #   |> Ecto.Multi.insert(:application_main_env, fn %{inserted_application: app, inserted_env: env} ->
  #     ApplicationMainEnv.new(app.id, env.id)
  #   end)
  #   |> Repo.transaction()

  #   app = Repo.get_by(App, name: "Counter")

  #   {:ok, %{inserted_user: unauthorized_user}} = register_user_nb(1, :dev)
  #   unauthorized_socket = socket(UserSocket, "socket_id", %{user: unauthorized_user})

  #   assert {:error, %{reason: [%{code: 24, message: "You are not authorized to join this app."}]}} =
  #            my_subscribe_and_join(unauthorized_socket, %{"app" => app.service_name})
  # end

  # test "Join app channel with authorized user", %{socket: _socket, user: user} do
  #   {:ok, %{inserted_user: authorized_user}} = register_user_nb(1, :dev)
  #   authorized_socket = socket(UserSocket, "socket_id", %{user: authorized_user})

  #   Ecto.Multi.new()
  #   |> Ecto.Multi.insert(
  #     :inserted_application,
  #     App.new(user.id, %{
  #       name: "Counter",
  #       color: "FFFFFF",
  #       icon: "60189"
  #     })
  #   )
  #   |> Ecto.Multi.insert(:inserted_env, fn %{inserted_application: app} ->
  #     Environment.new(app.id, user.id, nil, %{name: "live", is_ephemeral: false, is_public: false})
  #   end)
  #   |> Ecto.Multi.insert(:inserted_build, fn %{inserted_application: app} ->
  #     Build.new(user.id, app.id, @build_number, %{status: :success})
  #   end)
  #   |> Ecto.Multi.insert(:application_main_env, fn %{inserted_application: app, inserted_env: env} ->
  #     ApplicationMainEnv.new(app.id, env.id)
  #   end)
  #   |> Ecto.Multi.insert(:user_env_access, fn %{inserted_application: app, inserted_env: env} ->
  #     %UserEnvironmentAccess{user_id: authorized_user.id, environment_id: env.id}
  #     |> UserEnvironmentAccess.changeset()
  #   end)
  #   |> Ecto.Multi.update(:updated_env, fn %{inserted_env: env, inserted_build: build} ->
  #     Ecto.Changeset.change(env, deployed_build_id: build.id)
  #   end)
  #   |> Ecto.Multi.insert(:inserted_deployment, fn %{
  #                                                   inserted_application: app,
  #                                                   inserted_env: env,
  #                                                   inserted_build: build
  #                                                 } ->
  #     Deployment.new(app.id, env.id, build.id, user.id, %{})
  #   end)
  #   |> Repo.transaction()

  #   app = Repo.get_by(App, name: "Counter")

  #   owstub =
  #     FaasStub.create_faas_stub()
  #     |> FaasStub.stub_app(app.service_name, @build_number)

  #   owstub
  #   |> FaasStub.stub_request_once(@manifest)
  #   |> FaasStub.stub_request_once(@data)
  #   |> FaasStub.stub_request_once(@widget)
  #   |> FaasStub.stub_request_once(@data2)
  #   |> FaasStub.stub_request_once(@widget2)

  #   assert {:ok, _reply, _socket} = my_subscribe_and_join(authorized_socket, %{"app" => app.service_name})

  #   :timer.sleep(500)
  # end

  defp my_subscribe_and_join(socket, params \\ %{}) do
    subscribe_and_join(socket, LenraWeb.AppChannel, "app", params)
  end
end
