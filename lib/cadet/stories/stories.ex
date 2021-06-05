defmodule Cadet.Stories.Stories do
  @moduledoc """
  Manages stories for the Source Academy game
  """

  import Ecto.Query

  alias Cadet.Repo
  alias Cadet.Accounts.User
  alias Cadet.Stories.Story

  @manage_stories_role ~w(staff admin)a

  # def list_stories(_user = %User{role: role}) do
  #   if role in @manage_stories_role do
  #     Repo.all(Story)
  #   else
  #     Story
  #     |> where(is_published: ^true)
  #     |> where([s], s.open_at <= ^Timex.now())
  #     |> Repo.all()
  #   end
  # end

  # def create_story(attrs = %{}, _user = %User{role: role}) do
  #   if role in @manage_stories_role do
  #     %Story{}
  #     |> Story.changeset(attrs)
  #     |> Repo.insert()
  #   else
  #     {:error, {:forbidden, "User not allowed to manage stories"}}
  #   end
  # end

  # def update_story(attrs = %{}, id, _user = %User{role: role}) do
  #   if role in @manage_stories_role do
  #     case Repo.get(Story, id) do
  #       nil ->
  #         {:error, {:not_found, "Story not found"}}

  #       story ->
  #         story
  #         |> Story.changeset(attrs)
  #         |> Repo.update()
  #     end
  #   else
  #     {:error, {:forbidden, "User not allowed to manage stories"}}
  #   end
  # end

  # def delete_story(id, _user = %User{role: role}) do
  #   if role in @manage_stories_role do
  #     case Repo.get(Story, id) do
  #       nil -> {:error, {:not_found, "Story not found"}}
  #       story -> Repo.delete(story)
  #     end
  #   else
  #     {:error, {:forbidden, "User not allowed to manage stories"}}
  #   end
  # end
end
