defmodule Cadet.Course do
  @moduledoc """
  Course context contains domain logic for Course administration
  management such as discussion groups, materials, and announcements
  """
  use Cadet, :context

  alias Cadet.Accounts.User
  alias Cadet.Course.{Announcement, Group, Material, Upload}

  @doc """
  Create announcement entity using specified user as poster
  """
  def create_announcement(poster = %User{}, attrs = %{}) do
    changeset =
      %Announcement{}
      |> Announcement.changeset(attrs)
      |> put_assoc(:poster, poster)

    Repo.insert(changeset)
  end

  @doc """
  Edit Announcement with specified ID entity by specifying changes
  """
  def edit_announcement(id, changes = %{}) when is_ecto_id(id) do
    announcement = Repo.get(Announcement, id)

    if announcement == nil do
      {:error, :not_found}
    else
      changeset = Announcement.changeset(announcement, changes)
      Repo.update(changeset)
    end
  end

  @doc """
  Get Announcement with specified ID
  """
  def get_announcement(id) when is_ecto_id(id) do
    Announcement
    |> Repo.get(id)
    |> Repo.preload(:poster)
  end

  @doc """
  Delete Announcement with specified ID
  """
  def delete_announcement(id) when is_ecto_id(id) do
    announcement = Repo.get(Announcement, id)

    if announcement == nil do
      {:error, :not_found}
    else
      Repo.delete(announcement)
    end
  end

  @doc """
  Create group entity with given name
  """
  def create_group(name, leader, mentor) do
    changeset =
      %Group{}
      |> Group.changeset(%{name: name})
      |> put_assoc(:leader, leader)
      |> put_assoc(:mentor, mentor)

    Repo.insert(changeset)
  end

  @doc """
  Adds given student to given group
  """
  def add_student_to_group(group, student) do
    student
    |> Repo.preload(:group)
    |> User.changeset()
    |> put_assoc(:group, group)
    |> Repo.update()
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
