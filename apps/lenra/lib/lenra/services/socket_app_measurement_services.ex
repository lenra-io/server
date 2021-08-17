defmodule Lenra.SocketAppMeasurementServices do
  @moduledoc """
    The service that manages the client's applications measurements.
  """
  require Logger

  alias Lenra.{Repo, SocketAppMeasurement}

  def get(id) do
    Repo.get(SocketAppMeasurement, id)
  end

  def get_by(clauses) do
    Repo.get_by(SocketAppMeasurement, clauses)
  end

  def create(params) do
    Repo.insert(SocketAppMeasurement.new(params))
  end
end
