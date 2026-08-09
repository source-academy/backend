defmodule Cadet.Chatbot.Slug do
  @moduledoc """
  Shared slugification for pixelbot document keys and S3 object names.
  """

  @spec slugify(String.t()) :: String.t()
  def slugify(string) when is_binary(string) do
    string
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "-")
    |> String.trim("-")
    |> case do
      "" -> "document"
      slug -> slug
    end
  end

  @doc """
  Appends `-1`, `-2`, ... to `base` until `taken?` returns false.
  """
  @spec unique(String.t(), (String.t() -> boolean())) :: String.t()
  def unique(base, taken?) when is_function(taken?, 1) do
    if taken?.(base) do
      find_free_suffix(base, taken?, 1)
    else
      base
    end
  end

  defp find_free_suffix(base, taken?, n) do
    candidate = "#{base}-#{n}"

    if taken?.(candidate) do
      find_free_suffix(base, taken?, n + 1)
    else
      candidate
    end
  end
end
