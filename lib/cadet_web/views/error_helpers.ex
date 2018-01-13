defmodule CadetWeb.ErrorHelpers do
  @moduledoc """
  Conveniences for translating and building error messages.
  """
  use Phoenix.HTML

  def error_tag(form, field) do
    Enum.map(Keyword.get_values(form.errors, field), fn error ->
      {reason, _} = error
      content_tag(:span, to_string(field) <> " " <> reason, class: "sa-error")
    end)
  end
end
