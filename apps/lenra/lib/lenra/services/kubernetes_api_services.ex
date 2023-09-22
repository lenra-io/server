defmodule Lenra.KubernetesApiServices do
  @moduledoc """
  The service used to call Kubernetes API.
  Curently only support the request to create a new pipeline.
  """

  alias Lenra.Apps
  require Logger

  @doc """
  Create a new pipeline to build the app.
  The service_name is the app service name used to set the docker image url.
  The app_repository is the url of the git repository of the app.
  The build_id is the id of the freshly created build. It is used to set to create the runner callback url
  The build_number is the number of the freshly created build. It us used to set the docker image URL.
  """
  def create_pipeline(service_name, app_repository, app_repository_branch, build_id, build_number) do
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

    {:ok, _} =
      Finch.build(:post, secrets_url, headers, secret_body)
      |> Finch.request(PipelineHttp)
      |> response()

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
              initContainers: [
                %{
                  name: "get-lenra",
                  image: "alpine/curl",
                  command: ["/bin/sh"],
                  args: ["-c", "/tmp/lenra-scripts/get-lenra.sh"],
                  imagePullPolicy: "IfNotPresent",
                  volumeMounts: [
                    %{
                      mountPath: "/tmp/lenra",
                      name: "lenra"
                    },
                    %{
                      mountPath: "/tmp/lenra-scripts",
                      name: "lenra-scripts"
                    }
                  ]
                },
                %{
                  name: "get-app",
                  image: "alpine/git",
                  command: ["/bin/sh"],
                  args: ["-c", "/tmp/lenra-scripts/get-app.sh"],
                  envFrom: [
                    %{
                      secretRef: %{
                        name: build_name
                      }
                    }
                  ],
                  imagePullPolicy: "IfNotPresent",
                  volumeMounts: [
                    %{
                      mountPath: "/tmp/app",
                      name: "app"
                    },
                    %{
                      mountPath: "/tmp/lenra-scripts",
                      name: "lenra-scripts"
                    }
                  ]
                }
              ],
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
                      mountPath: "/tmp/app",
                      name: "app"
                    },
                    %{
                      mountPath: "/tmp/lenra",
                      name: "lenra"
                    },
                    %{
                      mountPath: "/tmp/lenra-scripts",
                      name: "lenra-scripts"
                    }
                  ],
                  workingDir: "/tmp/app/"
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
                },
                %{
                  name: "app",
                  emptyDir: %{}
                },
                %{
                  name: "lenra",
                  emptyDir: %{}
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

    Finch.build(:post, jobs_url, headers, body)
    |> Finch.request(PipelineHttp)
    |> response()
  end

  defp response({:ok, %Finch.Response{status: status_code, body: body}})
       when status_code in [200, 201, 202] do
    %{"metadata" => %{"name" => name}} = Jason.decode!()
    {:ok, %{"id" => name}}
  end

  defp response({:error, %Mint.TransportError{reason: reason}}) do
    raise "Kubernetes API could not be reached. It should not happen. #{reason}"
  end

  defp response({:ok, %Finch.Response{status: status_code, body: body}})
       when status_code not in [200, 201, 202] do
    raise "Kubernetes API error (#{status_code}) #{body}"
  end
end
