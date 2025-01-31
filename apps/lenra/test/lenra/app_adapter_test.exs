defmodule LenraWeb.AppAdapterTest do
  @moduledoc """
    Test the app adapter
  """
  use Lenra.RepoCase, async: true

  alias Lenra.{Apps, Repo}
  alias Lenra.Errors.BusinessError
  alias Lenra.FaasStub
  alias Lenra.GitlabStubHelper
  alias Lenra.Subscriptions.Subscription
  alias LenraWeb.AppAdapter

  setup do
    GitlabStubHelper.create_gitlab_stub()
    {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()
    {:ok, %{inserted_application: app, inserted_env: env}} = create_and_return_application(user, "test")

    {:ok, app: app, env: env}
  end

  defp create_and_return_application(user, name) do
    Apps.create_app(user.id, %{
      name: name,
      color: "FFFFFF",
      icon: "60189"
    })
  end

  describe "get_function_name/1" do
    test "returns function name when app is built", %{app: app, env: env} do
      {:ok, %{inserted_build: build}} =
        Apps.create_build(app.creator_id, app.id, %{
          commit_hash: "abcdef"
        })
        |> Repo.transaction()

      function_name = FaasStub.get_function_name(app.service_name, build.build_number)

      {:ok, %{inserted_deployment: deployment}} = Apps.create_deployment(env.id, build.id, app.creator_id)

      {:ok, _} =
        Ecto.Multi.new()
        |> Ecto.Multi.update(
          :updated_deployment,
          Ecto.Changeset.change(deployment, status: :success)
        )
        |> Ecto.Multi.run(:updated_env, fn _repo, %{updated_deployment: updated_deployment} ->
          env
          |> Ecto.Changeset.change(deployment_id: updated_deployment.id)
          |> Repo.update()
        end)
        |> Repo.transaction()

      assert AppAdapter.get_function_name(app.service_name) == function_name
    end

    test "returns error tuple when app is not built", %{app: app} do
      assert AppAdapter.get_function_name(app.service_name) == BusinessError.application_not_built_tuple()
    end
  end

  describe "get_env_id/1" do
    test "returns environment id", %{app: app, env: env} do
      assert AppAdapter.get_env_id(app.service_name) == env.id
    end
  end

  describe "get_scale_options/1" do
    test "returns scale options without subscription nor scale options", %{app: app} do
      assert AppAdapter.get_scale_options(app.service_name) == %{scale_min: 0, scale_max: 1}
    end

    test "returns scale options without subscription with scale options", %{app: app, env: env} do
      Apps.create_env_scale_options(env.id, %{
        min: 2,
        max: 5
      })

      assert AppAdapter.get_scale_options(app.service_name) == %{scale_min: 0, scale_max: 1}
    end

    test "returns scale options with subscription without scale options", %{app: app} do
      subscription =
        Subscription.new(%{
          application_id: app.id,
          start_date: DateTime.utc_now(),
          end_date: DateTime.utc_now() |> DateTime.add(1000, :second),
          plan: "month"
        })

      Repo.insert(subscription)

      assert AppAdapter.get_scale_options(app.service_name) == %{scale_min: 0, scale_max: 5}
    end

    test "returns scale options with subscription with min scale options", %{app: app, env: env} do
      {:ok, _} = Apps.create_env_scale_options(env.id, %{
        min: 2
      })

      subscription =
        Subscription.new(%{
          application_id: app.id,
          start_date: DateTime.utc_now(),
          end_date: DateTime.utc_now() |> DateTime.add(1000, :second),
          plan: "month"
        })

      Repo.insert(subscription)

      assert AppAdapter.get_scale_options(app.service_name) == %{scale_min: 2, scale_max: 5}
    end

    test "returns scale options with subscription with max scale options", %{app: app, env: env} do
      {:ok, _} = Apps.create_env_scale_options(env.id, %{
        max: 5
      })

      subscription =
        Subscription.new(%{
          application_id: app.id,
          start_date: DateTime.utc_now(),
          end_date: DateTime.utc_now() |> DateTime.add(1000, :second),
          plan: "month"
        })

      Repo.insert(subscription)

      assert AppAdapter.get_scale_options(app.service_name) == %{scale_min: 0, scale_max: 5}
    end

    test "returns scale options with subscription with min and max scale options", %{app: app, env: env} do
      {:ok, _} = Apps.create_env_scale_options(env.id, %{
        min: 2,
        max: 5
      })

      subscription =
        Subscription.new(%{
          application_id: app.id,
          start_date: DateTime.utc_now(),
          end_date: DateTime.utc_now() |> DateTime.add(1000, :second),
          plan: "month"
        })

      Repo.insert(subscription)

      assert AppAdapter.get_scale_options(app.service_name) == %{scale_min: 2, scale_max: 5}
    end

    test "returns scale options with subscription with reversed min and max scale options", %{app: app, env: env} do
      {:ok, _} = Apps.create_env_scale_options(env.id, %{
        min: 2,
        max: 1
      })

      subscription =
        Subscription.new(%{
          application_id: app.id,
          start_date: DateTime.utc_now(),
          end_date: DateTime.utc_now() |> DateTime.add(1000, :second),
          plan: "month"
        })

      Repo.insert(subscription)

      assert AppAdapter.get_scale_options(app.service_name) == %{scale_min: 2, scale_max: 2}
    end
  end
end
