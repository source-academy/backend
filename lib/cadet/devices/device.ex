defmodule Cadet.Devices.Device do
  @moduledoc """
  Represents a remote execution device.
  """

  use Cadet, :model

  @type t :: %__MODULE__{}

  schema "devices" do
    field(:secret, :string)
    field(:type, :string)

    field(:client_key, :binary)
    field(:client_cert, :binary)

    timestamps()
  end

  @required_fields ~w(secret type)a
  @optional_fields ~w(client_key client_cert)a

  def changeset(device, params \\ %{}) do
    device
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
