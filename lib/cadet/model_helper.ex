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
end
