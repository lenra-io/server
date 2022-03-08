defmodule Lenra.ServiceGetLatestCgu do
  @moduledoc """
    The service that get the latest CGU.
  """
  alias Lenra.{Cgu, Repo}

  def get_latest_cgu do
    Repo.get_by(Cgu)
  end
end
