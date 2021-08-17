defmodule Lenra.ActionLogsService do
  @moduledoc """
    The service that manages the openfaas measurements.
  """
  require Logger

  alias Lenra.{Repo, ActionLogs}

  def get_by(clauses) do
    Repo.get_by(ActionLogs, clauses)
  end

  def create(params) do
    Repo.insert(ActionLogs.new(params))
  end
end
