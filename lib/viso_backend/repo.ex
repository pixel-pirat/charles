defmodule VisoBackend.Repo do
  use Ecto.Repo,
    otp_app: :viso_backend,
    adapter: Ecto.Adapters.Postgres
end
