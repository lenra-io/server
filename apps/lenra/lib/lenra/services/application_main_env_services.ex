defmodule Lenra.ApplicationMainEnvServices do
  @moduledoc """
    The service that manages the different possible actions on an application main environment.
  """
  alias Lenra.{ApplicationMainEnv, Environment, Repo}

  def get(app_id) do
    main_env = Repo.get_by(ApplicationMainEnv, application_id: app_id)
    Repo.fetch_by(Environment, id: main_env.environment_id)
  end
end
