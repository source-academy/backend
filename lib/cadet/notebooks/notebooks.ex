defmodule Cadet.Notebooks.Notebooks do
  @moduledoc """
  Manages notebooks for Source Academy
  """
  use Cadet, [:context, :display]

  import Ecto.Query

  alias Cadet.Repo
  alias Cadet.Notebooks.{Notebook, Cell, Environment}
  alias Cadet.Accounts.CourseRegistration

  def list_notebook_for_user(user_id, course_id) do
    role =
      Repo.one(
        from(cr in CourseRegistration,
          where: cr.user == ^user_id and cr.course == ^course_id,
          select: cr.role
        )
      )

    if role == :admin do
      Notebook
      |> join(:inner, [n], cr in CourseRegistration, on: cr.id == n.course_registration)
      |> where([n, cr], cr.role == :admin)
      |> where([n], n.is_published == false)
      |> Repo.all()
    else
      Notebook
      |> where(course: ^course_id)
      |> where(user: ^user_id)
      |> Repo.all()
    end
  end

  def list_published_notebooks(course_id) do
    Notebook
    |> where(course: ^course_id)
    |> where(is_published: true)
    |> Repo.all()
  end

  def list_notebook_cells(notebook_id) do
    Cell
    |> where(notebook: ^notebook_id)
    |> preload(:environment)
    |> Repo.all()
  end

  def create_notebook(attrs = %{}, course_id, user_id, course_registration_id) do
    case %Notebook{}
         |> Notebook.changeset(
           attrs
           |> Map.put(:course_id, course_id)
           |> Map.put(:user_id, user_id)
           |> Map.put(:course_registration_id, course_registration_id)
         )
         |> Repo.insert() do
      {:ok, _} = result ->
        result

      {:error, changeset} ->
        {:error, {:bad_request, full_error_messages(changeset)}}
    end
  end

  def create_cell(attrs = %{}, notebook_id, environment_id) do
    case %Cell{}
         |> Cell.changeset(
           attrs
           |> Map.put(:notebook, notebook_id)
           |> Map.put(:environment, environment_id)
         )
         |> Repo.insert() do
      {:ok, _} = result ->
        result

      {:error, changeset} ->
        {:error, {:bad_request, full_error_messages(changeset)}}
    end
  end

  def create_environment(attrs = %{}) do
    case %Environment{}
         |> Environment.changeset(attrs)
         |> Repo.insert() do
      {:ok, _} = result ->
        result

      {:error, changeset} ->
        {:error, {:bad_request, full_error_messages(changeset)}}
    end
  end

  def update_notebook(attrs = %{}, id) do
    case Repo.get(Notebook, id) do
      nil ->
        {:error, {:not_found, "Notebook not found"}}

      notebook ->
        notebook
        |> Notebook.changeset(attrs)
        |> Repo.update()
    end
  end

  def update_cell(attrs = %{}, cell_id, notebook_id) do
    case Repo.get(Cell, cell_id) do
      nil ->
        {:error, {:not_found, "Cell not found"}}

      cell ->
        if cell.notebook == notebook_id do
          cell
          |> Cell.changeset(attrs)
          |> Repo.update()
        else
          {:error, {:forbidden, "Cell is not found in that notebook"}}
        end
    end
  end

  def delete_notebook(id) do
    case Repo.get(Notebook, id) do
      nil ->
        {:error, {:not_found, "Notebook not found"}}

      notebook ->
        Repo.delete(notebook)
    end
  end

  def delete_cell(cell_id, notebook_id) do
    case Repo.get(Cell, cell_id) do
      nil ->
        {:error, {:not_found, "Cell not found"}}

      cell ->
        if cell.notebook == notebook_id do
          Repo.delete(cell)
        else
          {:error, {:forbidden, "Cell is not found in that notebook"}}
        end
    end
  end
end
