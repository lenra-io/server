defmodule Lenra.Apps.Builder.DockerAdapter do
  @moduledoc false

  @behaviour Lenra.Apps.Builder.Adapter

  @impl true
  def build_app(repository_url, repository_branch, build_image, callback_url) do
    # TODO: call Docker Runner service
  end
end
