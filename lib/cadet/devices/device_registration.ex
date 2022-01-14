defmodule Cadet.Devices.DeviceRegistration do
  @moduledoc """
  Represents a registration of a remote execution device by a user.
  """

  use Cadet, :model

  alias Cadet.Accounts.User
  alias Cadet.Devices.Device

  @type t :: %__MODULE__{}

  schema "device_registrations" do
    field(:title, :string)

    belongs_to(:user, User)
    belongs_to(:device, Device)

    timestamps()
  end

  @required_fields ~w(title user_id device_id)a

  def changeset(device, params \\ %{}) do
    device
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
  end
end
