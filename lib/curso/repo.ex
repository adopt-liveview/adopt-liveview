defmodule Curso.Repo do
  use Ecto.Repo,
    otp_app: :curso,
    adapter: Ecto.Adapters.Postgres
end
