defmodule LenraWeb.AppChannelTest do
  @moduledoc """
    Test the `LenraWeb.AppChannel` module
  """
  use LenraWeb.ChannelCase, async: false
  alias LenraWeb.UserSocket
  alias Lenra.FaasStub, as: AppStub

  alias Lenra.{
    Repo,
    LenraApplication,
    Build,
    Environment,
    ApplicationMainEnv,
    Deployment
  }

  alias ApplicationRunner.ListenersCache

  @service_name "hello-world"
  @build_number 1
  @listener_name "HiBob"
  @listener_code ListenersCache.generate_listeners_key(@listener_name, %{})

  @manifest %{"manifest" => %{"entrypoint" => "test"}}

  @data %{"data" => %{"user" => %{"name" => "World"}}}
  @data2 %{"data" => %{"user" => %{"name" => "Bob"}}}

  @textfield %{
    "type" => "textfield",
    "value" => "Hello World",
    "onChanged" => %{"action" => @listener_name}
  }

  @textfield2 %{
    "type" => "textfield",
    "value" => "Hello Bob",
    "onChanged" => %{"action" => @listener_name}
  }

  @transformed_textfield %{
    "type" => "textfield",
    "value" => "Hello World",
    "onChanged" => %{"code" => @listener_code}
  }

  @widget %{"widget" => %{"type" => "flex", "children" => [@textfield]}}
  @widget2 %{"widget" => %{"type" => "flex", "children" => [@textfield2]}}

  @expected_ui %{"root" => %{"type" => "flex", "children" => [@transformed_textfield]}}
  @expected_patch_ui %{
    "patch" => [%{"op" => "replace", "path" => "/root/children/0/value", "value" => "Hello Bob"}]
  }

  setup do
    {:ok, %{inserted_user: user}} = register_john_doe()
    socket = socket(UserSocket, "socket_id", %{user: user})

    owstub =
      AppStub.create_faas_stub()
      |> AppStub.stub_app(@service_name, @build_number)

    %{socket: socket, owstub: owstub, user: user}
  end

  test "No app called, should return an error", %{socket: socket} do
    res = my_subscribe_and_join(socket)
    assert {:error, %{reason: "No App Name"}} == res
    refute_push("ui", _)
  end

  test "Base use case with simple app", %{socket: socket, owstub: owstub, user: user} do
    # owstub
    # |> AppStub.expect_deploy_app_once(%{"ok" => "200"})

    Ecto.Multi.new()
    |> Ecto.Multi.insert(
      :inserted_application,
      LenraApplication.new(user.id, %{
        name: "Counter",
        service_name: @service_name,
        color: "FFFFFF",
        icon: "60189"
      })
    )
    |> Ecto.Multi.insert(:inserted_env, fn %{inserted_application: app} ->
      Environment.new(app.id, user.id, nil, %{name: "live", is_ephemeral: false})
    end)
    |> Ecto.Multi.insert(:inserted_build, fn %{inserted_application: app} ->
      Build.new(user.id, app.id, @build_number, %{status: :success})
    end)
    |> Ecto.Multi.insert(:application_main_env, fn %{inserted_application: app, inserted_env: env} ->
      ApplicationMainEnv.new(app.id, env.id)
    end)
    |> Ecto.Multi.update(:updated_env, fn %{inserted_env: env, inserted_build: build} ->
      Ecto.Changeset.change(env, deployed_build_id: build.id)
    end)
    |> Ecto.Multi.insert(:inserted_deployment, fn %{inserted_application: app, inserted_env: env, inserted_build: build} ->
      Deployment.new(app.id, env.id, build.id, user.id, %{})
    end)
    |> Repo.transaction()

    # Base use case. Call InitData then MainUI then call the listener
    # and the next MainUI should not be called but taken from cache instead
    owstub
    |> AppStub.stub_request_once(@manifest)
    |> AppStub.stub_request_once(@data)
    |> AppStub.stub_request_once(@widget)
    |> AppStub.stub_request_once(@data2)
    |> AppStub.stub_request_once(@widget2)

    # Join the channel
    {:ok, _, socket} = my_subscribe_and_join(socket, %{"app" => @service_name})

    # Check that the correct data is stored into the socket
    assert %{
             user: ^user
           } = socket.assigns

    # Check that we receive a "ui" event with the final UI
    assert_push("ui", @expected_ui)

    # We simulate an event from the UI
    push(socket, "run", %{"code" => @listener_code})

    # Check that we receive a "patchUi" event with corresponding patch
    assert_push("patchUi", @expected_patch_ui)

    Process.unlink(socket.channel_pid)
    ref = leave(socket)

    assert_reply(ref, :ok)

    # Waiting for monitor to write measurements in db
    :timer.sleep(500)
  end

  defp my_subscribe_and_join(socket, params \\ %{}) do
    subscribe_and_join(socket, LenraWeb.AppChannel, "app", params)
  end
end
