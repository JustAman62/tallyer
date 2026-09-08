defmodule Tallyer.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      TallyerWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:tallyer, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Tallyer.PubSub},
      {Registry, name: Tallyer.GameRegistry, keys: :unique},
      Tallyer.GameSupervisor,
      TallyerWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Tallyer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    TallyerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
