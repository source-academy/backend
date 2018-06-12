defmodule Cadet.Accounts.Authorization do
  @moduledoc """
  The User entity represents a user.
  It stores basic information such as name, NUSNET ID, and e-mail.
  Each user is associated to one `role` which determines the access level
  of the user.
  """
  use Cadet, :model

  alias Cadet.Accounts.User
  alias Cadet.Accounts.Provider

  schema "authorizations" do
    field(:provider, Provider)
    field(:uid, :string)
    field(:token, :string)
    field(:refresh_token, :string)
    field(:expires_at, :integer)

    belongs_to(:user, User)
  end

  @required_fields ~w(provider uid token)a
  @optional_fields ~w(refresh_token expires_at)a

  def changeset(authorization, params \\ %{}) do
    authorization
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint(:uid, name: :authorizations_provider_uid_index)
  end
end
