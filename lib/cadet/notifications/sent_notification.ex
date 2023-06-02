defmodule Cadet.Notifications.SentNotification do
  @moduledoc """
  SentNotification entity to store all sent notifications for logging (and future purposes etc. mailbox)
  """
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
    |> cast(attrs, [:content, :course_reg_id])
    |> validate_required([:content, :course_reg_id])
    |> foreign_key_constraint(:course_reg_id)
  end
end
