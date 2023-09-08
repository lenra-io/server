defmodule ApplicationRunner.Scheduler do
  @moduledoc false
  use Quantum, otp_app: :application_runner, name: {:via, :swarm, __MODULE__}
end
