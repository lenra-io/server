defmodule Lenra.DockerRunnerServices do
  @moduledoc """
  The service used to call Kubernetes API.
  Curently only support the request to create a new pipeline.
  """

  alias Lenra.Apps
  alias Lenra.Apps.Build
  alias Lenra.Apps.Deployment
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

    base64_repository = Base.encode64(app_repository)
    base64_repository_branch = Base.encode64(app_repository_branch || "")

    base64_callback_url = Base.encode64("#{runner_callback_url}/runner/builds/#{build_id}?secret=#{runner_secret}")

    base64_image_name = Base.encode64(Apps.image_name(service_name, build_number))

    secret_body =
      Jason.encode!(%{
        apiVersion: "v1",
        kind: "Secret",
        type: "Opaque",
        metadata: %{
          name: build_name,
          namespace: kubernetes_build_namespace
        },
        data: %{
          APP_REPOSITORY: base64_repository,
          REPOSITORY_BRANCH: base64_repository_branch,
          CALLBACK_URL: base64_callback_url,
          IMAGE_NAME: base64_image_name
        }
      })

    secret_response =
      Finch.build(:post, secrets_url, headers, secret_body)
      |> Finch.request(PipelineHttp)
      |> response(:secret)

    case secret_response do
      {:ok, _} ->
        :ok

      :secret_exist ->
        Finch.build(:delete, secrets_url <> "/#{build_name}", headers)
        |> Finch.request(PipelineHttp)
        |> response(:secret)

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
    Logger.critical("#{__MODULE__} kubernetes returned status code #{status_code} with message #{inspect(body)}")

    {:error, :kubernetes_error}
  end
end
