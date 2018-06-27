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
      # Start your own worker by calling: Cadet.Worker.start_link(arg1, arg2, arg3)
      # worker(Cadet.Worker, [arg1, arg2, arg3]),
      # Start the GuardianDB sweeper
      worker(Guardian.DB.Token.SweeperServer, [])
    ]

    children =
      if Mix.env() != :test do
        children ++ [worker(Cadet.Public.Updater, [])]
      else
        children
      end

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
