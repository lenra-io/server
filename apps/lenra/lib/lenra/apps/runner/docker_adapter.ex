defmodule Lenra.Apps.Runner.DockerAdapter do
  @moduledoc false

  @behaviour Lenra.Apps.Runner.Adapter

  @impl true
  def build_app(repository_url, repository_branch, build_image, callback_url) do
    # TODO: call Docker Runner service
  end
end
