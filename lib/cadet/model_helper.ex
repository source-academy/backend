defmodule Cadet.ModelHelper do
  @moduledoc """
  This module contains helper for the models.
  """

  alias Timex.Timezone

  def convert_date(params, field) do
    if is_binary(params[field]) && params[field] != "" do
      timezone = Timezone.get("Asia/Singapore", Timex.now)
      date = params[field]
        |> String.to_integer
        |> Timex.from_unix()
        |> Timezone.convert(timezone)
      Map.put(params, field, date)
    else
      params
    end
  end
  
  defp validate_open_close_date(changeset) do
    validate_change(changeset, :open_at, fn :open_at, open_at ->
      if Timex.before?(open_at, get_field(changeset, :close_at)) do
        []
      else
        [open_at: "Open date must be before close date"]
      end
    end)
  end
end
