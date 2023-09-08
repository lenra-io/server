defmodule ApplicationRunner.Webhooks.WebhookTest do
  @moduledoc false

  use ApplicationRunner.RepoCase

  alias ApplicationRunner.Contract.{Environment, User}
  alias ApplicationRunner.Repo
  alias ApplicationRunner.Webhooks.Webhook

  test "Insert Webhook into database successfully" do
    env =
      Environment.new()
      |> Repo.insert!()

    Webhook.new(env.id, %{
      "action" => "test",
      "props" => %{
        "prop1" => "1",
        "prop2" => "2"
      }
    })
    |> Repo.insert!()

    webhook = Enum.at(Repo.all(Webhook), 0)

    assert webhook.action == "test"

    assert webhook.props == %{
             "prop1" => "1",
             "prop2" => "2"
           }
  end

  test "Webhook with invalid env_id should not work" do
    webhook =
      Webhook.new(1, %{
        "action" => "test",
        "props" => %{
          "prop1" => "1",
          "prop2" => "2"
        }
      })

    assert_raise Ecto.InvalidChangesetError, fn -> Repo.insert!(webhook) end
  end

  test "Webhook without action should not work" do
    webhook =
      Webhook.new(1, %{
        "props" => %{
          "prop1" => "1",
          "prop2" => "2"
        }
      })

    assert webhook.valid? == false
    assert [action: _reason] = webhook.errors
  end

  test "Insert Webhook with no props into database successfully" do
    env =
      Environment.new()
      |> Repo.insert!()

    Webhook.new(env.id, %{
      "action" => "test"
    })
    |> Repo.insert!()

    webhook = Enum.at(Repo.all(Webhook), 0)

    assert webhook.action == "test"
  end

  test "Insert Webhook with user into database successfully" do
    env =
      Environment.new()
      |> Repo.insert!()

    user =
      User.new(%{"email" => "test@lenra.io"})
      |> Repo.insert!()

    Webhook.new(env.id, %{
      "user_id" => user.id,
      "action" => "test"
    })
    |> Repo.insert!()

    webhook = Enum.at(Repo.all(Webhook), 0)

    assert webhook.action == "test"
    assert webhook.user_id == user.id

    preload_user = Repo.preload(webhook, :user)

    assert preload_user.user.id == user.id
  end
end
