defmodule Cadet.Application do
  @moduledoc false

  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(Cadet.Repo, []),
      # Start the endpoint when the application starts
      supervisor(CadetWeb.Endpoint, []),
      {Phoenix.PubSub, [name: Cadet.PubSub, adapter: Phoenix.PubSub.PG2]},
      # Start your own worker by calling: Cadet.Worker.start_link(arg1, arg2, arg3)
      # worker(Cadet.Worker, [arg1, arg2, arg3]),
      # Start the GuardianDB sweeper
      worker(Guardian.DB.Token.SweeperServer, []),
      # Start the Quantum scheduler
      worker(Cadet.Jobs.Scheduler, []),
      # Start the Oban instance
      {Oban, Application.fetch_env!(:cadet, Oban)},
      {Samly.Provider, []}
    ]

    children =
      case Application.get_env(:cadet, :openid_connect_providers) do
        nil -> children
        providers -> children ++ [worker(OpenIDConnect.Worker, [providers])]
      end

    {:ok, _} = Logger.add_backend(Sentry.LoggerBackend)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Cadet.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    CadetWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
