defmodule Cadet.Notifications.SentNotification do
  use Ecto.Schema
  import Ecto.Changeset
  alias Cadet.Accounts.CourseRegistration

  schema "sent_notifications" do
    field(:content, :string)

    belongs_to(:course_reg, CourseRegistration)

    timestamps()
  end

  @doc false
  def changeset(sent_notification, attrs) do
    sent_notification
    |> cast(attrs, [:content])
    |> validate_required([:content])
  end
end
