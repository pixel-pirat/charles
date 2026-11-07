defmodule VisoBackend.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Temporary checkpoint while diagnosing a silent boot failure on
    # Render — remove once the deploy is confirmed healthy.
    IO.puts("VisoBackend.Application.start/2 reached")

    children = [
      VisoBackendWeb.Telemetry,
      VisoBackend.Repo,
      {DNSCluster, query: Application.get_env(:viso_backend, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: VisoBackend.PubSub},
      VisoBackendWeb.Presence,
      # Start a worker by calling: VisoBackend.Worker.start_link(arg)
      # {VisoBackend.Worker, arg},
      # Start to serve requests, typically the last entry
      VisoBackendWeb.Endpoint
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: VisoBackend.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    VisoBackendWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
