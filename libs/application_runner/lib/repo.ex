defmodule ApplicationRunner.Repo do
  use Ecto.Repo, otp_app: :application_runner, adapter: Ecto.Adapters.Postgres
end
