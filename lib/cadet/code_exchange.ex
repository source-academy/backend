defmodule Cadet.TokenExchange do
  @moduledoc """
  The TokenExchange entity stores short-lived codes to be exchanged for long-lived auth tokens.
  """
  use Cadet, :model

  import Ecto.Query

  alias Cadet.Repo
  alias Cadet.Accounts.User

  @primary_key {:code, :string, []}
  schema "token_exchange" do
    field(:generated_at, :utc_datetime_usec)
    field(:expires_at, :utc_datetime_usec)

    belongs_to(:user, User)

    timestamps()
  end

  @required_fields ~w(code generated_at expires_at user_id)a

  def get_by_code(code) do
    case Repo.get_by(__MODULE__, code: code) do
      nil ->
        {:error, "Not found"}

      struct ->
        if Timex.before?(struct.expires_at, Timex.now()) do
          {:error, "Expired"}
        else
          struct = Repo.preload(struct, :user)
          Repo.delete(struct)
          {:ok, struct}
        end
    end
  end

  def delete_expired do
    now = Timex.now()

    Repo.delete_all(from(c in __MODULE__, where: c.expires_at < ^now))
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
  end

  def insert(attrs) do
    changeset =
      %__MODULE__{}
      |> changeset(attrs)

    changeset
    |> Repo.insert()
  end
end
