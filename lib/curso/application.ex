defmodule Curso.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    :logger.add_handler(:my_sentry_handler, Sentry.LoggerHandler, %{
      config: %{metadata: [:file, :line]}
    })

    children = [
      CursoWeb.Telemetry,
      # Curso.Repo,
      {DNSCluster, query: Application.get_env(:curso, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Curso.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Curso.Finch},
      # Start a worker by calling: Curso.Worker.start_link(arg)
      # {Curso.Worker, arg},
      # Start to serve requests, typically the last entry
      CursoWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Curso.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CursoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
