defmodule Lenra.Kubernetes.ApiServices do
  @moduledoc """
  The service used to call Kubernetes API.
  Curently only support the request to create a new pipeline.
  """

  alias Lenra.Apps
  alias Lenra.Apps.Build
  alias Lenra.Apps.Deployment
  alias Lenra.Kubernetes.StatusDynSup
  alias Lenra.Repo
  require Logger

  @doc """
  Create a new pipeline to build the app.
  The service_name is the app service name used to set the docker image url.
  The app_repository is the url of the git repository of the app.
  The build_id is the id of the freshly created build. It is used to set to create the runner callback url
  The build_number is the number of the freshly created build. It us used to set the docker image URL.
  """
  def create_pipeline(
        service_name,
        app_repository,
        app_repository_branch,
        build_id,
        build_number,
        retry \\ 0
      ) do
    runner_callback_url = Application.fetch_env!(:lenra, :runner_callback_url)
    runner_secret = Application.fetch_env!(:lenra, :runner_secret)
    kubernetes_api_url = Application.fetch_env!(:lenra, :kubernetes_api_url)
    kubernetes_api_token = Application.fetch_env!(:lenra, :kubernetes_api_token)
    kubernetes_build_namespace = Application.fetch_env!(:lenra, :kubernetes_build_namespace)
    kubernetes_build_scripts = Application.fetch_env!(:lenra, :kubernetes_build_scripts)
    kubernetes_build_secret = Application.fetch_env!(:lenra, :kubernetes_build_secret)

    secrets_url = "#{kubernetes_api_url}/api/v1/namespaces/#{kubernetes_build_namespace}/secrets"
    jobs_url = "#{kubernetes_api_url}/apis/batch/v1/namespaces/#{kubernetes_build_namespace}/jobs"

    headers = [
      {"Authorization", "Bearer #{kubernetes_api_token}"},
      {"content-type", "application/json"}
    ]

    build_name = "build-#{service_name}-#{build_number}"

    secret_response = create_k8s_secret(build_name, kubernetes_build_namespace, %{
      APP_REPOSITORY: app_repository,
      REPOSITORY_BRANCH: app_repository_branch || "",
      CALLBACK_URL: "#{runner_callback_url}/runner/builds/#{build_id}?secret=#{runner_secret}",
      IMAGE_NAME: Apps.image_name(service_name, build_number)
    })

    case secret_response do
      {:ok} ->
        :ok

      :secret_exist ->

        if retry < 1 do
          create_pipeline(
            service_name,
            app_repository,
            app_repository_branch,
            build_id,
            build_number,
            retry + 1
          )
        else
          set_fail(build_id)
        end
    end

    body =
      Jason.encode!(%{
        apiVersion: "batch/v1",
        kind: "Job",
        metadata: %{
          name: build_name,
          namespace: kubernetes_build_namespace
        },
        spec: %{
          completions: 1,
          backoffLimit: 0,
          template: %{
            metadata: %{
              name: build_name
            },
            spec: %{
              containers: [
                %{
                  name: "build",
                  image: "docker:23.0.1-dind-rootless",
                  args: ["/tmp/lenra-scripts/build.sh"],
                  envFrom: [
                    %{
                      secretRef: %{
                        name: kubernetes_build_secret
                      }
                    },
                    %{
                      secretRef: %{
                        name: build_name
                      }
                    }
                  ],
                  securityContext: %{
                    privileged: true
                  },
                  imagePullPolicy: "IfNotPresent",
                  volumeMounts: [
                    %{
                      mountPath: "/tmp/lenra-scripts",
                      name: "lenra-scripts"
                    }
                  ]
                }
              ],
              restartPolicy: "Never",
              volumes: [
                %{
                  name: "lenra-scripts",
                  configMap: %{
                    name: kubernetes_build_scripts,
                    # 0555
                    defaultMode: 365
                  }
                }
              ]
            },
            resources: %{
              limits: %{
                cpu: "500m",
                memory: "1024Mi"
              },
              requests: %{
                cpu: "50m",
                memory: "100Mi"
              }
            }
          }
        }
      })

    response =
      Finch.build(:post, jobs_url, headers, body)
      |> Finch.request(PipelineHttp)
      |> response(:build)

    case response do
      {:ok, _data} = response ->
        response

      _error ->
        set_fail(build_id)
    end

    StatusDynSup.start_build_status(build_id, kubernetes_build_namespace, build_name)

    response
  end

  defp set_fail(build_id) do
    build = Repo.get(Build, build_id)
    deployment = Repo.get_by(Deployment, build_id: build_id)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:build, Build.update(build, %{status: :failure}))
    |> Ecto.Multi.update(
      :deployment,
      Ecto.Changeset.change(deployment, %{status: :failure})
    )
    |> Repo.transaction()
  end

  defp response({:ok, %Finch.Response{status: status_code, body: body}}, :secret)
       when status_code in [200, 201, 202] do
    {:ok, Jason.decode!(body)}
  end

  defp response({:ok, %Finch.Response{status: status_code, body: body}}, :build)
       when status_code in [200, 201, 202] do
    %{"metadata" => %{"name" => name}} = Jason.decode!(body)
    {:ok, %{"id" => name}}
  end

  defp response({:error, %Mint.TransportError{reason: reason}}, _atom) do
    raise "Kubernetes API could not be reached. It should not happen. #{reason}"
  end

  defp response(
         {:ok,
          %Finch.Response{
            status: status_code
          }},
         _atom
       )
       when status_code in [409] do
    :secret_exist
  end

  defp response({:ok, %Finch.Response{status: status_code, body: body}}, _atom) do
    Logger.critical("#{__MODULE__} kubernetes return status code #{status_code} with message #{inspect(body)}")

    {:error, :kubernetes_error}
  end

  defp get_k8s_secret(secret_name, namespace) do
    kubernetes_api_url = Application.fetch_env!(:lenra, :kubernetes_api_url)
    kubernetes_api_token = Application.fetch_env!(:lenra, :kubernetes_api_token)

    secrets_url = "#{kubernetes_api_url}/api/v1/namespaces/#{namespace}/secrets/#{secret_name}"

    headers = [
      {"Authorization", "Bearer #{kubernetes_api_token}"},
      {"content-type", "application/json"}
    ]

    secret_response = Finch.build(:get, secrets_url, headers)
        |> Finch.request(PipelineHttp)
        |> response(:secret)

    case secret_response do
      {:ok, body} ->
          %{"data" => secret_data} = body
          Enum.into(Enum.map(secret_data, fn ({key, value}) -> {key, Base.decode64(value)} end, %{}))
      _ -> {:secret_not_exist}
    end
  end

  defp create_k8s_secret(secret_name, namespace, data) do
    kubernetes_api_url = Application.fetch_env!(:lenra, :kubernetes_api_url)
    kubernetes_api_token = Application.fetch_env!(:lenra, :kubernetes_api_token)

    secrets_url = "#{kubernetes_api_url}/api/v1/namespaces/#{namespace}/secrets/#{secret_name}"

    headers = [
      {"Authorization", "Bearer #{kubernetes_api_token}"},
      {"content-type", "application/json"}
    ]

    secret_body =
      Jason.encode!(%{
        apiVersion: "v1",
        kind: "Secret",
        type: "Opaque",
        metadata: %{
          name: secret_name,
          namespace: namespace
        },
        data: Enum.into(Enum.map(data, fn ({key, value}) -> {key, Base.encode64(value)} end, %{}))
      })

    secret_response =
      Finch.build(:post, secrets_url, headers, secret_body)
      |> Finch.request(PipelineHttp)
      |> response(:secret)

    case secret_response do
      {:ok, _} ->
        :ok

      :secret_exist -> { :secret_exist }
    end
  end

  defp update_k8s_secret(secret_name, namespace, secrets) do
    kubernetes_api_url = Application.fetch_env!(:lenra, :kubernetes_api_url)
    kubernetes_api_token = Application.fetch_env!(:lenra, :kubernetes_api_token)

    secrets_url = "#{kubernetes_api_url}/api/v1/namespaces/#{namespace}/secrets/#{secret_name}"

    headers = [
      {"Authorization", "Bearer #{kubernetes_api_token}"},
      {"content-type", "application/json"}
    ]

    secret_body =
        Jason.encode!(%{
          apiVersion: "v1",
          kind: "Secret",
          metadata: %{
            name: secret_name,
          },
          data: Enum.into(Enum.map(secrets, fn ({key, value}) -> {key, Base.encode64(value)} end, %{}))
        })

    secret_response = Finch.build(:put, secrets_url, headers)
    |> Finch.request(PipelineHttp)
    |> response(:secret)

    case secret_response do
      {:ok, _} -> {:ok}
      _ -> {:secret_not_exist}
    end

  end

  defp delete_k8s_secret(secret_name, namespace) do
    kubernetes_api_url = Application.fetch_env!(:lenra, :kubernetes_api_url)
    kubernetes_api_token = Application.fetch_env!(:lenra, :kubernetes_api_token)

    secrets_url = "#{kubernetes_api_url}/api/v1/namespaces/#{namespace}/secrets/#{secret_name}"

    headers = [
      {"Authorization", "Bearer #{kubernetes_api_token}"},
      {"content-type", "application/json"}
    ]

    secret_response = Finch.build(:delete, secrets_url, headers)
        |> Finch.request(PipelineHttp)
        |> response(:secret)

    case secret_response do
      {:ok, _} -> {:ok}
      _ -> {:secret_not_exist}
    end
  end

  def get_environment_secrets(service_name, env_id) do
    kubernetes_apps_namespace = Application.fetch_env!(:lenra, :kubernetes_apps_namespace)
    case get_k8s_secret('#{service_name}_secret_#{env_id}', kubernetes_apps_namespace) do
      {:ok, secrets} -> Enum.map(secrets, fn ({key, value}) -> key end)
      {:secret_not_found} -> {:error, :secret_not_found}
      _ -> {:error, :unexpected_response}
    end
  end
  def create_environment_secrets(service_name, env_id, secrets) do
    kubernetes_apps_namespace = Application.fetch_env!(:lenra, :kubernetes_apps_namespace)
    case create_k8s_secret('#{service_name}_secret_#{env_id}', kubernetes_apps_namespace, secrets) do
      {:ok, secrets} -> {:ok, Enum.map(secrets, fn ({key, value}) -> key end)}
      {:secret_exist} -> {:error, :secret_exist}
      _ -> {:error, :unexpected_response}
    end
  end
  def update_environment_secrets(service_name, env_id, secrets) do
    kubernetes_apps_namespace = Application.fetch_env!(:lenra, :kubernetes_apps_namespace)
    case get_k8s_secret('#{service_name}_secret_#{env_id}', kubernetes_apps_namespace) do
      {:ok, current_secrets} ->
        case update_k8s_secret('#{service_name}_secret_#{env_id}', kubernetes_apps_namespace, Map.merge(current_secrets, secrets)) do
          {:ok, secrets} -> {:ok, Enum.map(secrets, fn ({key, value}) -> key end)}
          {:secret_not_found} -> {:error, :secret_not_found}
          _ -> {:error, :unexpected_response}
        end
      error -> error
    end
  end
  def delete_environment_secrets(service_name, env_id, key) do
    kubernetes_apps_namespace = Application.fetch_env!(:lenra, :kubernetes_apps_namespace)
    case get_k8s_secret('#{service_name}_secret_#{env_id}', kubernetes_apps_namespace) do
      {:ok, current_secrets} ->
        case length(Map.keys(current_secrets)) do
          len when len <= 1 ->
            case delete_k8s_secret('#{service_name}_secret_#{env_id}', kubernetes_apps_namespace) do
              {:ok, _} -> {:ok, []}
              {:secret_not_found} -> {:error, :secret_not_found}
              _ -> {:error, :unexpected_response}
            end
          _ ->
            case update_k8s_secret('#{service_name}_secret_#{env_id}', kubernetes_apps_namespace, Map.drop(current_secrets, [key])) do
              {:ok, secrets} -> {:ok, Enum.map(secrets, fn ({key, value}) -> key end)}
              {:secret_not_found} -> {:error, :secret_not_found}
              _ -> {:error, :unexpected_response}
            end
        end
      error -> error
    end
  end
end
