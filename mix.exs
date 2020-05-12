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
      extra_applications: [:sentry, :logger, :que, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support", "test/factories"]
  defp elixirc_paths(:dev), do: ["lib", "test/factories"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:arc, "~> 0.11.0"},
      {:arc_ecto, "~> 0.11.0"},
      {:csv, "~> 2.3.0"},
      {:ecto_enum, "~> 1.0"},
      {:ex_aws, "~> 2.0"},
      {:ex_aws_kms, "~> 2.0"},
      {:ex_aws_lambda, "~> 2.0"},
      {:ex_aws_s3, "~> 2.0"},
      {:ex_json_schema, "~> 0.5"},
      {:ex_machina, "~> 2.3"},
      {:floki, "~> 0.26.0"},
      {:gettext, "~> 0.11"},
      {:guardian, "~> 2.0"},
      {:guardian_db, "~> 2.0"},
      {:hackney, "~> 1.6"},
      {:httpoison, "~> 1.0", override: true},
      {:inch_ex, "~> 2.0", only: [:dev, :test]},
      {:joken, "~> 2.0"},
      {:jason, "~> 1.1"},
      {:jsx, "~> 2.8"},
      {:phoenix, "~> 1.4.0"},
      {:phoenix_ecto, "~> 4.0"},
      {:phoenix_swagger, "~> 0.8"},
      {:plug_cowboy, "~> 2.0"},
      {:poison, "~> 3.1"},
      {:postgrex, ">= 0.0.0"},
      {:quantum, "~> 2.3.0"},
      {:que, "~> 0.10.0"},
      {:sentry, "~> 7.0"},
      {:sweet_xml, "~> 0.6.6"},
      {:timex, "~> 3.0"},
      # TODO: Remove the override once ex_aws released the new version
      #       without the dependency on xml_builder. Waste my time urgh
      {:xml_builder, "~> 2.0", override: true},
      {:credo, "~> 1.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.2", only: [:dev, :test], runtime: false},
      {:distillery, "~> 2.0.14", runtime: false},
      {:excoveralls, "~> 0.8", only: :test},
      {:exvcr, "~> 0.10", only: :test},
      {:faker, "~> 0.10", only: [:dev, :test]},
      {:git_hooks, "~> 0.3.1", only: [:dev, :test]},
      {:mock, "~> 0.3.0", only: :test}
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
      "phx.digest": ["cadet.digest"],
      sentry_recompile: ["deps.compile sentry --force", "compile"]
    ]
  end
end
