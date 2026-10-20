defmodule Cadet.Chatbot.OpenAIEmbeddingsTest do
  use ExUnit.Case

  import Mock

  alias Cadet.Chatbot.OpenAIEmbeddings

  setup do
    original_key = Application.get_env(:openai, :api_key)
    Application.put_env(:openai, :api_key, "sk-test")
    on_exit(fn -> Application.put_env(:openai, :api_key, original_key) end)
  end

  test "returns the embedding as floats" do
    body = Jason.encode!(%{"data" => [%{"embedding" => [1, 0.5]}]})

    with_mock HTTPoison, post: fn _url, _body, _headers, _opts -> ok(200, body) end do
      assert OpenAIEmbeddings.embed("hello") == {:ok, [1.0, 0.5]}
    end
  end

  test "returns an error for a non-2xx response" do
    with_mock HTTPoison, post: fn _url, _body, _headers, _opts -> ok(429, "slow down") end do
      assert OpenAIEmbeddings.embed("hello") ==
               {:error, {:openai_embeddings_error, 429, "slow down"}}
    end
  end

  test "returns an error for an invalid response body" do
    with_mock HTTPoison, post: fn _url, _body, _headers, _opts -> ok(200, "{}") end do
      assert OpenAIEmbeddings.embed("hello") == {:error, :invalid_openai_embeddings_response}
    end
  end

  test "returns the transport error" do
    with_mock HTTPoison,
      post: fn _url, _body, _headers, _opts -> {:error, %HTTPoison.Error{reason: :timeout}} end do
      assert OpenAIEmbeddings.embed("hello") == {:error, %HTTPoison.Error{reason: :timeout}}
    end
  end

  test "returns an error when no api key is configured" do
    Application.put_env(:openai, :api_key, "")
    assert OpenAIEmbeddings.embed("hello") == {:error, :missing_openai_api_key}
  end

  defp ok(status, body), do: {:ok, %HTTPoison.Response{status_code: status, body: body}}
end
