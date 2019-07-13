defmodule Cadet.Course do
  @moduledoc """
  Course context contains domain logic for Course administration
  management such as discussion groups and materials
  """
  use Cadet, :context

  import Ecto.Query

  alias Cadet.Accounts.User
  alias Cadet.Course.{Group, Material, Upload, Sourcecast}

  @doc """
  Get a group based on the group name or create one if it doesn't exist
  """
  @spec get_or_create_group(String.t()) :: {:ok, %Group{}} | {:error, Ecto.Changeset.t()}
  def get_or_create_group(name) when is_binary(name) do
    Group
    |> where(name: ^name)
    |> Repo.one()
    |> case do
      nil ->
        %Group{}
        |> Group.changeset(%{name: name})
        |> Repo.insert()

      group ->
        {:ok, group}
    end
  end

  @doc """
  Updates a group based on the group name or create one if it doesn't exist
  """
  @spec insert_or_update_group(map()) :: {:ok, %Group{}} | {:error, Ecto.Changeset.t()}
  def insert_or_update_group(params = %{name: name}) when is_binary(name) do
    Group
    |> where(name: ^name)
    |> Repo.one()
    |> case do
      nil ->
        Group.changeset(%Group{}, params)

      group ->
        Group.changeset(group, params)
    end
    |> Repo.insert_or_update()
  end

  # @doc """
  # Reassign a student to a discussion group.
  # This will un-assign student from the current discussion group
  # """
  # def assign_group(leader = %User{}, student = %User{}) do
  #   cond do
  #     leader.role == :student ->
  #       {:error, :invalid}

  #     student.role != :student ->
  #       {:error, :invalid}

  #     true ->
  #       Repo.transaction(fn ->
  #         {:ok, _} = unassign_group(student)

  #         %Group{}
  #         |> Group.changeset(%{})
  #         |> put_assoc(:leader, leader)
  #         |> put_assoc(:student, student)
  #         |> Repo.insert!()
  #       end)
  #   end
  # end

  # @doc """
  # Remove existing student from discussion group, no-op if a student
  # is unassigned
  # """
  # def unassign_group(student = %User{}) do
  #   existing_group = Repo.get_by(Group, student_id: student.id)

  #   if existing_group == nil do
  #     {:ok, nil}
  #   else
  #     Repo.delete(existing_group)
  #   end
  # end

  # @doc """
  # Get list of students under staff discussion group
  # """
  # def list_students_by_leader(staff = %User{}) do
  #   import Cadet.Course.Query, only: [group_members: 1]

  #   staff
  #   |> group_members()
  #   |> Repo.all()
  #   |> Repo.preload([:student])
  # end

  @doc """
  Upload a sourcecast file
  """
  def upload_sourcecast_file(uploader = %User{}, attrs = %{}) do
    changeset =
      %Sourcecast{}
      |> Sourcecast.changeset(attrs)
      |> put_assoc(:uploader, uploader)

    Repo.insert(changeset)
  end

  @doc """
  Delete a sourcecast file.
  """
  def delete_sourcecast_file(id) do
    sourcecast = Repo.get(Sourcecast, id)
    Upload.delete({sourcecast.file, sourcecast})
    Repo.delete(sourcecast)
  end

  @doc """
  Create a new folder to put material files in
  """
  def create_material_folder(uploader = %User{}, attrs = %{}) do
    create_material_folder(nil, uploader, attrs)
  end

  @doc """
  Create a new folder to put material files in
  """
  def create_material_folder(parent, uploader = %User{}, attrs = %{}) do
    changeset =
      %Material{}
      |> Material.folder_changeset(attrs)
      |> put_assoc(:uploader, uploader)

    case parent do
      %Material{} ->
        Repo.insert(put_assoc(changeset, :parent, parent))

      _ ->
        Repo.insert(changeset)
    end
  end

  @doc """
  Upload a material file to designated folder
  """
  def upload_material_file(folder = %Material{}, uploader = %User{}, attr = %{}) do
    changeset =
      %Material{}
      |> Material.changeset(attr)
      |> put_assoc(:uploader, uploader)
      |> put_assoc(:parent, folder)

    Repo.insert(changeset)
  end

  @doc """
  Delete a material file/directory. A directory tree
  is deleted recursively
  """
  def delete_material(id) when is_ecto_id(id) do
    material = Repo.get(Material, id)
    delete_material(material)
  end

  def delete_material(material = %Material{}) do
    if material.file do
      Upload.delete({material.file, material})
    end

    Repo.delete(material)
  end

  @doc """
  List material folder content
  """
  def list_material_folders(folder = %Material{}) do
    import Cadet.Course.Query, only: [material_folder_files: 1]
    Repo.all(material_folder_files(folder.id))
  end
end
