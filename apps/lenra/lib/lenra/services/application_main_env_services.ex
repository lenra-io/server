defmodule Lenra.ApplicationMainEnvServices do
  @moduledoc """
    The service that manages the different possible actions on an application main environment.
  """
  import Ecto.Query
  alias Lenra.{ApplicationMainEnv, Environment, Repo, UserEnvironmentAccess}
  require Logger

  def fetch(app_id) do
    Repo.fetch(ApplicationMainEnv, app_id)
  end
end
