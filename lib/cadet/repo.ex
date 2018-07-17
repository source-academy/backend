defmodule Cadet.Repo do
  use Ecto.Repo, otp_app: :cadet

  alias ExAws.KMS

  @env Mix.env()

  @doc """
  Dynamically obtains the database password from encrypted cipher text using
  AWS KMS (only in production).
  """
  def init(_, opts) do
    if @env == :prod do
      cipher_text =
        :cadet
        |> Application.fetch_env!(:aws)
        |> Keyword.get(:rds_cipher_text)

      key_id =
        :cadet
        |> Application.fetch_env!(:aws)
        |> Keyword.get(:rds_key_id)

      region =
        :cadet
        |> Application.fetch_env!(:aws)
        |> Keyword.get(:region)

      {:ok, kms_response} =
        cipher_text
        |> KMS.decrypt(KeyId: key_id)
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
