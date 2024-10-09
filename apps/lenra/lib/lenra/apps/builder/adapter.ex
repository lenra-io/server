defmodule Lenra.Apps.Builder.Adapter do
  @moduledoc false

  alias Lenra.Apps.Builder

  @callback build_app(Builder.repository_url(), Builder.repository_branch(), Builder.build_image(), Builder.callback_url()) :: :ok | {:error, any()}
end
