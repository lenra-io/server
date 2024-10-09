defmodule Lenra.Apps.Runner.Adapter do
  @moduledoc false

  alias Lenra.Apps.Runner

  @callback run(Builder.repository_url(), Builder.repository_branch(), Builder.build_image(), Builder.callback_url()) :: :ok | {:error, any()}
end
