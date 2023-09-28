defmodule Lenra.Kubernetes.StatusTask do
  use Task

  alias Lenra.Kubernetes

  def start_link(_args) do
    Task.start_link(__MODULE__, :run, [])
  end

  def run do
    try do
      Kubernetes.StatusDynSup.init_status()
      {:ok, []}
    catch
      _error ->
        {:error, :init_status_failed}
    end
  end
end
