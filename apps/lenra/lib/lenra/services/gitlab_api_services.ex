defmodule Lenra.GitlabApiServices do
  @moduledoc """
  The service used to call Gitlab API.
  Curently only support the request to create a new pipeline.
  """

  require Logger

  alias Lenra.DeploymentServices

  @doc """
  Create a new pipeline to build the app.
  The service_name is the app service name used to set the docker image url.
  The app_repository is the url of the git repository of the app.
  The build_id is the id of the freshly created build. It is used to set to create the runner callback url
  The build_number is the number of the freshly created build. It us used to set the docker image URL.
  """
  def create_pipeline(service_name, app_repostiory, build_id, build_number) do
    runner_callback_url = Application.fetch_env!(:lenra, :runner_callback_url)
    gitlab_api_url = Application.fetch_env!(:lenra, :gitlab_api_url)
    gitlab_api_token = Application.fetch_env!(:lenra, :gitlab_api_token)
    gitlab_project_id = Application.fetch_env!(:lenra, :gitlab_project_id)
    runner_secret = Application.fetch_env!(:lenra, :runner_secret)

    url = "#{gitlab_api_url}/projects/#{gitlab_project_id}/pipeline"

    headers = [
      {"PRIVATE-TOKEN", gitlab_api_token},
      {"content-type", "application/json"}
    ]

    body =
      Jason.encode!(%{
        "ref" => "master",
        "variables" => [
          %{"key" => "IMAGE_NAME", "value" => DeploymentServices.image_name(service_name, build_number)},
          %{
            "key" => "CALLBACK_URL",
            "value" => "#{runner_callback_url}/runner/builds/#{build_id}?secret=#{runner_secret}"
          },
          %{"key" => "APP_REPOSITORY", "value" => app_repostiory}
        ]
      })

    Finch.build(:post, url, headers, body)
    |> Finch.request(FaasHttp)
    |> response()
  end

  defp response({:ok, %Finch.Response{status: status_code}})
       when status_code in [200, 201, 202] do
    {:ok, nil}
  end

  defp response({:error, %Mint.TransportError{reason: _}}) do
    raise "Gitlab API could not be reached. It should not happen."
  end

  defp response({:ok, %Finch.Response{status: status_code, body: body}})
       when status_code not in [200, 201, 202] do
    raise "Gitlab API error (#{status_code}) #{body}"
  end
end
