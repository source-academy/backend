defmodule Cadet.Chatbot.CourseLlm do
  @moduledoc """
  Builds the OpenAI config for a course's Pixel calls, so they run on the course's own
  `llm_api_key`.
  """
  alias Cadet.Courses.Course
  alias CadetWeb.AICommentsHelpers

  # The openai dep ships no type for its config struct, so name one here for the call sites.
  @type t :: %OpenAI.Config{}

  @doc """
  Returns the course's OpenAI config, or why it can't.
  """
  @spec config(Course.t()) :: {:ok, t()} | {:error, :missing_key | atom()}
  def config(%Course{llm_api_key: key}) when is_nil(key) or key == "", do: {:error, :missing_key}

  def config(%Course{llm_api_key: encrypted}) do
    case AICommentsHelpers.decrypt_llm_api_key(encrypted) do
      {:ok, ""} -> {:error, :missing_key}
      {:ok, key} -> {:ok, %OpenAI.Config{api_key: key}}
      nil -> {:error, :missing_key}
      {:decrypt_error, reason} -> {:error, reason}
    end
  end
end
