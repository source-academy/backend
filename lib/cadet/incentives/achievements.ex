defmodule Cadet.Incentives.Achievements do
  @moduledoc """
  Stores `Achievement`s.
  """
  use Cadet, [:context, :display]

  alias Cadet.Incentives.Achievement

  import Ecto.Query

  @doc """
  Returns all achievements.

  This returns Achievement structs with prerequisites and goal association maps pre-loaded.
  """
  @spec get() :: [%Achievement{}]
  def get do
    Achievement
    |> preload([:prerequisites, :goals])
    |> Repo.all()
  end

  @spec upsert(map()) :: {:ok, %Achievement{}} | {:error, {:bad_request, String.t()}}
  @doc """
  Inserts a new achievement, or updates it if it already exists.
  """
  def upsert(attrs) when is_map(attrs) do
    case attrs[:uuid] || attrs["uuid"] do
      nil ->
        {:error, {:bad_request, "No UUID specified in Achievement"}}

      uuid ->
        Achievement
        |> preload([:prerequisites, :goals])
        |> Repo.get(uuid)
        |> (&(&1 || %Achievement{})).()
        |> Achievement.changeset(attrs)
        |> Repo.insert_or_update()
        |> case do
          result = {:ok, _} ->
            result

          {:error, changeset} ->
            {:error, {:bad_request, full_error_messages(changeset)}}
        end
    end
  end

  @spec upsert_many([map()]) :: {:ok, [%Achievement{}]} | {:error, {:bad_request, String.t()}}
  def upsert_many(many_attrs) when is_list(many_attrs) do
    Repo.transaction(fn ->
      for attrs <- many_attrs do
        case upsert(attrs) do
          {:ok, achievement} -> achievement
          {:error, error} -> Repo.rollback(error)
        end
      end
    end)
  end

  @doc """
  Deletes an achievement.
  """
  @spec delete(Ecto.UUID.t()) ::
          :ok | {:error, {:not_found, String.t()}}
  def delete(uuid) when is_binary(uuid) do
    case Achievement
         |> where(uuid: ^uuid)
         |> Repo.delete_all() do
      {0, _} -> {:error, {:not_found, "Achievement not found"}}
      {_, _} -> :ok
    end
  end
end
