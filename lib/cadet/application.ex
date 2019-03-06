defmodule Cadet.Application do
  @moduledoc false

  use Application

  alias Cadet.Updater

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

    # To supply command line args to phx.server, you must use the elixir/iex bin
    #     $ elixir --erl "--updater" -S mix phx.server
    #     $ iex --erl "--updater" -S mix phx.server
    # In the compiled binary howver, this is much simpler
    #     $ bin/cadet start --updater
    children =
      if Enum.any?(
           :init.get_plain_arguments(),
           &(&1 |> to_string() |> String.contains?("--updater"))
         ) do
        Task.async(&Updater.CS1101S.clone/0)

        children ++
          [
            # worker(Updater.Public, []),
            worker(Cadet.Jobs.Scheduler, [])
          ]
      else
        children
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
