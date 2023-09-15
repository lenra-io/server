defmodule ApplicationRunner.Webhooks.ServicesTest do
  @moduledoc false

  alias ApplicationRunner.EventHandler
  use ApplicationRunner.RepoCase

  alias ApplicationRunner.Contract
  alias ApplicationRunner.Environment
  alias ApplicationRunner.Environment.{Metadata, MetadataAgent}
  alias ApplicationRunner.Repo
  alias ApplicationRunner.Webhooks.{Webhook, WebhookServices}

  setup do
    {:ok, env} = Repo.insert(Contract.Environment.new())

    env_metadata = %Metadata{
      env_id: env.id,
      function_name: "test"
    }

    {:ok, _} = start_supervised({MetadataAgent, env_metadata})
    {:ok, _} = start_supervised({EventHandler, [id: env.id, mode: :env]})

    start_supervised({Environment.TokenAgent, env_metadata})

    user =
      %{email: "test@test.te"}
      |> Contract.User.new()
      |> Repo.insert!()

    bypass = Bypass.open(port: 1234)

    {:ok, %{env_id: env.id, user_id: user.id, bypass: bypass}}
  end

  defp handle_request(conn, callback) do
    {:ok, body, conn} = Plug.Conn.read_body(conn)

    body_decoded =
      if String.length(body) != 0 do
        Jason.decode!(body)
      else
        ""
      end

    callback.(body_decoded)

    case body_decoded do
      # Listeners "listener" in body
      %{"listener" => _listener} ->
        Plug.Conn.resp(conn, 200, "")
    end
  end

  test "Webhook should properly trigger listener", %{
    env_id: env_id,
    user_id: _user_id,
    bypass: bypass
  } do
    assert {:ok, webhook} =
             Webhook.new(env_id, %{"listener" => "listener", "props" => %{"propKey" => "propValue"}})
             |> Repo.insert()

    Bypass.stub(
      bypass,
      "POST",
      "/function/test",
      &handle_request(&1, fn body ->
        assert body["props"] == %{"propKey" => "propValue"}
        assert body["listener"] == "listener"
        assert body["event"] == %{"eventPropKey" => "eventPropValue"}
      end)
    )

    assert :ok == WebhookServices.trigger(webhook.uuid, %{"eventPropKey" => "eventPropValue"})
  end

  test "Trigger not existing webhook should return an error", %{
    env_id: _env_id,
    user_id: _user_id,
    bypass: _bypass
  } do
    assert {:error, %LenraCommon.Errors.TechnicalError{reason: :error_404}} =
             WebhookServices.trigger(Ecto.UUID.generate(), %{})
  end

  test "User specific Webhook should properly trigger listener", %{
    env_id: env_id,
    user_id: user_id,
    bypass: bypass
  } do
    assert {:ok, webhook} =
             Webhook.new(env_id, %{
               "user_id" => user_id,
               "listener" => "listener",
               "props" => %{"propKey" => "propValue"}
             })
             |> Repo.insert()

    Bypass.stub(
      bypass,
      "POST",
      "/function/test",
      &handle_request(&1, fn body ->
        assert body["props"] == %{"propKey" => "propValue"}
        assert body["listener"] == "listener"
        assert body["event"] == %{"eventPropKey" => "eventPropValue"}
      end)
    )

    assert :ok == WebhookServices.trigger(webhook.uuid, %{"eventPropKey" => "eventPropValue"})
  end

  test "Webhook create should work properly", %{
    env_id: env_id,
    user_id: _user_id,
    bypass: _bypass
  } do
    assert {:ok, _webhook} = WebhookServices.create(env_id, %{"listener" => "listener"})

    webhook = Enum.at(Repo.all(Webhook), 0)

    assert webhook.listener == "listener"
    assert webhook.environment_id == env_id
  end

  test "Webhook create with user should work", %{
    env_id: env_id,
    user_id: user_id,
    bypass: _bypass
  } do
    assert {:ok, webhook} =
             WebhookServices.create(env_id, %{"listener" => "listener", "user_id" => user_id})

    webhook_preload = Repo.preload(webhook, :user)

    assert webhook_preload.user.id == user_id
  end

  test "Webhook create without listener should not work", %{
    env_id: env_id,
    user_id: _user_id,
    bypass: _bypass
  } do
    assert {:error, _reason} = WebhookServices.create(env_id, %{})
  end

  test "Webhook create with invalid env_id should not work", %{
    env_id: _env_id,
    user_id: _user_id,
    bypass: _bypass
  } do
    assert {:error, _reason} = WebhookServices.create(-1, %{"listener" => "listener"})
  end

  test "Webhook get should work properly", %{env_id: env_id} do
    assert {:ok, _webhook} =
             Webhook.new(env_id, %{"listener" => "listener"})
             |> Repo.insert()

    webhooks = WebhookServices.get(env_id)

    assert Enum.at(webhooks, 0).listener == "listener"
  end

  test "Webhook get with no webhook in db should return an empty array", %{env_id: env_id} do
    assert [] == WebhookServices.get(env_id)
  end

  test "Webhook get should work properly with multiple webhooks", %{env_id: env_id} do
    assert {:ok, _first} =
             Webhook.new(env_id, %{"listener" => "first"})
             |> Repo.insert()

    assert {:ok, _second} =
             Webhook.new(env_id, %{"listener" => "second"})
             |> Repo.insert()

    webhooks = WebhookServices.get(env_id)

    assert Enum.at(webhooks, 0).listener == "first"
    assert Enum.at(webhooks, 1).listener == "second"
  end

  test "Get webhooks linked to specific user should work properly", %{env_id: env_id} do
    user =
      %{email: "test@test.te"}
      |> Contract.User.new()
      |> Repo.insert!()

    assert {:ok, _webhook} =
             Webhook.new(env_id, %{"listener" => "user_specific_webhook", "user_id" => user.id})
             |> Repo.insert()

    webhooks = WebhookServices.get(env_id, user.id)

    assert Enum.at(webhooks, 0).listener == "user_specific_webhook"
  end

  test "Get webhooks linked to specific user but no webhook in db should return empty array", %{
    env_id: env_id
  } do
    assert [] = WebhookServices.get(env_id, 1)
  end
end
