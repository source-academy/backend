defmodule CadetWeb.AICommentsHelpers do
  @moduledoc """
  Helper functions for Managing LLM related logic
  """

  def decrypt_llm_api_key(nil), do: nil

  def decrypt_llm_api_key(encrypted_key) do
    case Application.get_env(:openai, :encryption_key) do
      secret when is_binary(secret) and byte_size(secret) >= 16 ->
        key = binary_part(secret, 0, min(32, byte_size(secret)))

        case Base.decode64(encrypted_key) do
          {:ok, decoded} ->

            with [iv, tag, ciphertext] <- :binary.split(decoded, <<"|">>, [:global]) do
              case :crypto.crypto_one_time_aead(:aes_gcm, key, iv, ciphertext, "", tag, false) do
                plain_text when is_binary(plain_text) -> {:ok, plain_text}
                _ -> {:decrypt_error, :decryption_failed}
              end
            else
              _ -> {:error, :invalid_format}
            end



          _ ->
            Logger.error(
              "Failed to decode encrypted key, is it a valid AES-256 key of 16, 24 or 32 bytes?"
            )

            {:decrypt_error, :decryption_failed}
        end

      _ ->
        Logger.error("Encryption key not configured")
        {:decrypt_error, :invalid_encryption_key}
    end
  end

  def encrypt_llm_api_key(llm_api_key) do
    secret = Application.get_env(:openai, :encryption_key)

    if is_binary(secret) and byte_size(secret) >= 16 do
      # Use first 16 bytes for AES-128, 24 for AES-192, or 32 for AES-256
      key = binary_part(secret, 0, min(32, byte_size(secret)))
      # Use AES in GCM mode for encryption
      iv = :crypto.strong_rand_bytes(16)

      {ciphertext, tag} =
        :crypto.crypto_one_time_aead(
          :aes_gcm,
          key,
          iv,
          llm_api_key,
          "",
          true
        )

      # Store both the IV, ciphertext and tag
      encrypted = Base.encode64(iv <> "|" <> tag <> "|" <> ciphertext)
    else
      {:error, :invalid_encryption_key}
    end
  end

end
