defmodule Lenra.GitlabStubHelper do
  @moduledoc """
  The helper to create a fake gitlab API.
  Curently only support one url : /projects/{{gitlab_project_id}}/pipeline.
  The server is started on port 4567
  """

  use ExUnit.CaseTemplate

  def create_gitlab_stub do
    gitlab_project_id = Application.fetch_env!(:lenra, :gitlab_project_id)
    url = "projects/#{gitlab_project_id}/pipeline"

    opts = [port: 4567]

    opts
    |> Bypass.open()
    |> Bypass.stub("POST", url, &handle_resp/1)
  end

  defp handle_resp(conn) do
    {:ok, body, conn} = Plug.Conn.read_body(conn)
    body_decoded = Jason.decode!(body)

    Plug.Conn.resp(
      conn,
      200,
      Jason.encode!(%{
        "id" => Enum.at(String.split(Enum.at(body_decoded["variables"], 0)["value"], ":"), 1),
        "status" => "pending",
        "project_id" => Enum.at(conn.path_info, 1)
      })
    )
  end
end
