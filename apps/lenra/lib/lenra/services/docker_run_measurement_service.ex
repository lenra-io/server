defmodule Lenra.DockerRunMeasurementServices do
  @moduledoc """
    The service that manages the client's applications measurements.
  """
  alias Lenra.{DockerRunMeasurement, Repo}
  require Logger

  def get(id) do
    Repo.get(DockerRunMeasurement, id)
  end

  def get_by(clauses) do
    Repo.get_by(DockerRunMeasurement, clauses)
  end

  def create(params) do
    Repo.insert(DockerRunMeasurement.new(params))
  end
end
