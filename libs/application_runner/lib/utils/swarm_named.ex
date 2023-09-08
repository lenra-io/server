defmodule SwarmNamed do
  @moduledoc """
  This is a helper module to normalize swarm naming for process modules (Agent, GenServer, Supervisor..)
  """
  defmacro __using__(_opts) do
    quote do
      def get_name(identifier) do
        {__MODULE__, identifier}
      end

      def get_full_name(identifier) do
        {:via, :swarm, get_name(identifier)}
      end
    end
  end
end
