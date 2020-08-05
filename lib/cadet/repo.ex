defmodule Cadet.Repo do
  use Ecto.Repo, otp_app: :cadet, adapter: Ecto.Adapters.Postgres

  alias ExAws.SecretsManager

  @dialyzer {:no_match, init: 2}

  @doc """
  Dynamically obtains the database credentials from AWS Secrets Manager.
  """
  def init(_, opts) do
    case Keyword.get(opts, :rds_secret_name) do
      nil ->
        {:ok, opts}

      rds_secret_name ->
        %{"SecretString" => credentials_json} =
          rds_secret_name |> SecretsManager.get_secret_value() |> ExAws.request!()

        credentials = Jason.decode!(credentials_json)

        {:ok,
         Keyword.merge(opts,
           username: credentials["username"],
           password: credentials["password"],
           hostname: credentials["host"],
           port: credentials["port"],
           database: credentials["dbname"]
         )}
    end
  end
end
