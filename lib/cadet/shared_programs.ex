defmodule Cadet.SharedPrograms do
  @moduledoc """
  The SharedPrograms context.
  """

  import Ecto.Query, warn: false
  alias Cadet.Repo

  alias Cadet.SharedPrograms.SharedProgram

  @doc """
  Returns the list of shared_programs.

  ## Examples

      iex> list_shared_programs()
      [%SharedProgram{}, ...]

  """
  def list_shared_programs do
    Repo.all(SharedProgram)
  end

  @doc """
  Gets a single shared_program.

  Raises `Ecto.NoResultsError` if the Shared program does not exist.

  ## Examples

      iex> get_shared_program!(123)
      %SharedProgram{}

      iex> get_shared_program!(456)
      ** (Ecto.NoResultsError)

  """
  def get_shared_program!(id), do: Repo.get!(SharedProgram, id)

  def get_shared_program_by_uuid!(uuid) do
    case Repo.get_by(SharedProgram, uuid: uuid) do
      nil -> raise "SharedProgram not found for UUID #{uuid}"
      shared_program -> shared_program
    end
  end

  @doc """
  Creates a shared_program.

  ## Examples

      iex> create_shared_program(%{field: value})
      {:ok, %SharedProgram{}}

      iex> create_shared_program(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_shared_program(attrs \\ %{}) do
    %SharedProgram{}
    |> SharedProgram.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a shared_program.

  ## Examples

      iex> update_shared_program(shared_program, %{field: new_value})
      {:ok, %SharedProgram{}}

      iex> update_shared_program(shared_program, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_shared_program(%SharedProgram{} = shared_program, attrs) do
    shared_program
    |> SharedProgram.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a shared_program.

  ## Examples

      iex> delete_shared_program(shared_program)
      {:ok, %SharedProgram{}}

      iex> delete_shared_program(shared_program)
      {:error, %Ecto.Changeset{}}

  """
  def delete_shared_program(%SharedProgram{} = shared_program) do
    Repo.delete(shared_program)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking shared_program changes.

  ## Examples

      iex> change_shared_program(shared_program)
      %Ecto.Changeset{data: %SharedProgram{}}

  """
  def change_shared_program(%SharedProgram{} = shared_program, attrs \\ %{}) do
    SharedProgram.changeset(shared_program, attrs)
  end
end
