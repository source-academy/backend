defmodule Cadet.Mixfile do
  use Mix.Project

  def project do
    [
      app: :cadet,
      version: "0.0.1",
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers() ++ [:phoenix_swagger],
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
      dialyzer: [
        plt_add_apps: [:mix, :ex_unit],
        plt_local_path: "priv/plts",
        plt_core_path: "priv/plts"
      ],
      releases: [
        cadet: [
          steps: [:assemble, :tar]
        ]
      ]
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
      {:arc, "~> 0.11"},
      {:arc_ecto, "~> 0.11"},
      {:corsica, "~> 2.1"},
      {:csv, "~> 3.2"},
      {:ecto_enum, "~> 1.0"},
      {:ex_aws, "~> 2.1", override: true},
      {:ex_aws_lambda, "~> 2.0"},
      {:ex_aws_s3, "~> 2.0"},
      {:ex_aws_secretsmanager, "~> 2.0"},
      {:ex_aws_sts, "~> 2.1"},
      {:ex_json_schema, "~> 0.7.4"},
      {:ex_machina, "~> 2.3"},
      {:ex_rated, "~> 2.0"},
      {:guardian, "~> 2.0"},
      {:guardian_db, "~> 2.0"},
      {:hackney, "~> 1.6"},
      {:httpoison, "~> 2.3", override: true},
      {:jason, "~> 1.2"},
      {:openai, "~> 0.6.2"},
      {:openid_connect, "~> 0.2"},
      {:phoenix, "~> 1.5"},
      {:phoenix_view, "~> 2.0"},
      {:phoenix_ecto, "~> 4.0"},
      {:phoenix_swagger, "~> 0.8"},
      {:plug_cowboy, "~> 2.0"},
      {:postgrex, ">= 0.0.0"},
      {:quantum, "~> 3.0"},
      {:que, "~> 0.10"},
      {:recase, "~> 0.7", override: true},
      {:samly, "~> 1.0"},
      {:sentry, "~> 11.0"},
      {:sweet_xml, "~> 0.6"},
      {:timex, "~> 3.7"},

      # notifiations system dependencies
      {:phoenix_html, "~> 4.2"},
      {:bamboo, "~> 2.5.0"},
      {:bamboo_ses, "~> 0.4.1"},
      {:bamboo_phoenix, "~> 1.0.0"},
      {:oban, "~> 2.13"},

      # development dependencies
      {:configparser_ex, "~> 4.0", only: [:dev, :test]},
      {:credo, "~> 1.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:distillery, "~> 2.1", runtime: false},
      {:faker, "~> 0.10", only: [:dev, :test]},
      {:git_hooks, "~> 0.4", only: [:dev, :test]},

      # RC to fix https://github.com/rrrene/inch_ex/pull/68
      {:inch_ex, "~> 2.1-rc", only: [:dev, :test]},

      # unit testing dependencies
      {:bypass, "~> 2.1", only: :test},
      {:excoveralls, "~> 0.8", only: :test},
      {:exvcr, "~> 0.10", only: :test},
      {:mock, "~> 0.3.0", only: :test},

      # Dependencies for logger unit testing
      {:mox, "~> 1.2", only: :test},
      {:logger_backends, "~> 1.0.0", only: :test},

      # The following are indirect dependencies, but we need to override the
      # versions due to conflicts
      {:jsx, "~> 3.1", override: true},
      {:xml_builder, "~> 2.1", override: true}
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
