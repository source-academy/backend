defmodule Cadet.Mixfile do
  use Mix.Project

  def project do
    [
      app: :cadet,
      version: "0.0.1",
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext, :phoenix_swagger] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      aliases: aliases(),
      deps: deps(),
      dialyzer: [plt_add_apps: [:mix, :ex_unit]]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Cadet.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.3.0"},
      {:phoenix_pubsub, "~> 1.0"},
      {:phoenix_ecto, "~> 3.2"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 2.10"},
      {:gettext, "~> 0.11"},
      {:cowboy, "~> 1.0"},
      {:dotenv, "~> 2.0.0"},
      {:ecto_enum, "~> 1.0"},
      {:ex_machina, "~> 2.1"},
      {:pbkdf2_elixir, "~> 0.12"},
      {:comeonin, "~> 4.0"},
      {:guardian, "~> 1.0"},
      {:guardian_db, "~> 1.0"},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.8", only: :test},
      {:dialyxir, "~> 0.5", only: [:dev, :test], runtime: false},
      {:arc, "~> 0.8.0"},
      {:arc_ecto, "~> 0.7.0"},
      {:timex, "~> 3.0"},
      {:timex_ecto, "~> 3.0"},
      {:phoenix_swagger, "~> 0.8"},
      {:ex_json_schema, "~> 0.5"},
      {:pre_commit, "~> 0.3.4", only: [:dev, :test]}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"],
      "phx.server": ["cadet.server"],
      "phx.digest": ["cadet.digest"]
    ]
  end
end
