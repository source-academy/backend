defmodule Cadet.Notifications.NotificationType do
  use Ecto.Schema
  import Ecto.Changeset

  schema "notification_types" do
    field(:is_autopopulated, :boolean, default: false)
    field(:is_enabled, :boolean, default: false)
    field(:name, :string)
    field(:template_file_name, :string)

    timestamps()
  end

  @doc false
  def changeset(notification_type, attrs) do
    notification_type
    |> cast(attrs, [:name, :template_file_name, :is_enabled, :is_autopopulated])
    |> validate_required([:name, :template_file_name, :is_enabled, :is_autopopulated])
  end
end
