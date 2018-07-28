defmodule Cadet.Repo do
  use Ecto.Repo, otp_app: :cadet
  use Cadet.DeploymentHelper

  alias ExAws.KMS

  @dialyzer {:no_match, init: 2}

  @doc """
  Dynamically obtains the database password from encrypted cipher text using
  AWS KMS (only in production).
  """
  def init(_, opts) do
    if_compilation Mix.env() == :prod do
      cipher_text =
        :cadet
        |> Application.fetch_env!(:aws)
        |> Keyword.get(:rds_cipher_text)

      region =
        :cadet
        |> Application.fetch_env!(:aws)
        |> Keyword.get(:region)

      {:ok, kms_response} =
        cipher_text
        |> KMS.decrypt()
        |> ExAws.request(region: region)

      password =
        kms_response
        |> Map.get("Plaintext")
        |> Base.decode64!()

      {:ok, Keyword.put(opts, :password, password)}
    else
      {:ok, opts}
    end
  end
end
