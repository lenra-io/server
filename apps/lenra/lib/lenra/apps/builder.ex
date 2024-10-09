defmodule Lenra.Apps.Builder do
  @moduledoc """
  Main API for building app
  """

  @type repository_url :: String.t()
  @type repository_branch :: String.t() | nil
  @type build_image :: String.t()
  @type callback_url :: String.t()

  @behaviour Lenra.Apps.Builder.Adapter

  @doc """
  Build a Lenra app
  """
  @impl true
  @spec build_app(repository_url, repository_branch, build_image, callback_url) :: :ok | {:error, DeliveryError.t()}
  def build_app(repository_url, repository_branch, build_image, callback_url) do
    adapter().build_app(repository_url, repository_branch, build_image, callback_url)
  end

  defp adapter do
    Application.get_env(:lenra, :builder_adapter, Lenra.Apps.Builder.DockerAdapter)
  end
end
