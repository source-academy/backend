defmodule CadetWeb.ErrorHelpers do
  @moduledoc """
  Conveniences for translating and building error messages.
  """
  use Phoenix.HTML

  def error_tag(form, field) do
    Enum.map(Keyword.get_values(form.errors, field), fn error ->
      {reason, _} = error
      field_name = field |> to_string |> String.capitalize
      content_tag(:span, field_name <> " " <> reason, class: "sa-error")
    end)
  end
end
