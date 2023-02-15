defmodule Cadet.Email do
  use Bamboo.Phoenix, view: CadetWeb.EmailView
  import Bamboo.Email
  alias Cadet.Mailer

  def avenger_backlog_email(avenger, ungraded_submissions) do
    cond do
      is_nil(avenger.email) -> nil
      true ->
        base_email()
          |> to(avenger.email)
          |> assign(:avenger_name, avenger.name)
          |> assign(:submissions, ungraded_submissions)
          |> subject("Backlog for #{avenger.name}")
          |> render("backlog.html")
          |> Mailer.deliver_now()
    end
  end

  defp base_email() do
    new_email()
    |> from("noreply@sourceacademy.org")
    |> put_html_layout({CadetWeb.LayoutView, "email.html"})
  end
end
