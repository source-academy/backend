defmodule Cadet.Courses do
  @moduledoc """
  Courses context contains domain logic for Course administration
  management such as course configuration, discussion groups and materials
  """
  use Cadet, [:context, :display]

  import Ecto.Query

  alias Cadet.Accounts.CourseRegistration

  alias Cadet.Courses.{
    AssessmentConfig,
    Course,
    Group,
    Sourcecast,
    SourcecastUpload
  }

  @doc """
  Returns the course configuration for the specified course.
  """
  @spec get_course_config(integer) ::
          {:ok, %Course{}} | {:error, {:bad_request, String.t()}}
  def get_course_config(course_id) when is_ecto_id(course_id) do
    case retrieve_course(course_id) do
      nil ->
        {:error, {:bad_request, "Invalid course id"}}

      course ->
        assessment_configs =
          AssessmentConfig
          |> where(course_id: ^course_id)
          |> Repo.all()
          |> Enum.sort(&(&1.order < &2.order))
          |> Enum.map(& &1.type)

        {:ok, Map.put_new(course, :assessment_configs, assessment_configs)}
    end
  end

  @doc """
  Updates the general course configuration for the specified course
  """
  @spec update_course_config(integer, %{}) ::
          {:ok, %Course{}} | {:error, {:bad_request, String.t()} | {:error, Ecto.Changeset.t()}}
  def update_course_config(course_id, params) when is_ecto_id(course_id) do
    case retrieve_course(course_id) do
      nil ->
        {:error, {:bad_request, "Invalid course id"}}

      course ->
        course
        |> Course.changeset(params)
        |> Repo.update()
    end
  end

  defp retrieve_course(course_id) when is_ecto_id(course_id) do
    Course
    |> where(id: ^course_id)
    |> Repo.one()
  end

  def get_assessment_configs(course_id) when is_ecto_id(course_id) do
    AssessmentConfig
    |> where([at], at.course_id == ^course_id)
    |> order_by(:order)
    |> Repo.all()
  end

  def mass_upsert_or_delete_assessment_configs(course_id, configs) do
    if not is_list(configs) do
      {:error, {:bad_request, "Invalid parameter(s)"}}
    else
      configs_length = configs |> length()

      with true <- configs_length <= 5,
           true <- configs_length >= 1,
           true <-
             configs
             |> Enum.with_index(1)
             |> Enum.all?(fn {elem, i} -> Map.has_key?(elem, :order) && elem.order == i end) do
        (configs ++ List.duplicate(nil, 5 - configs_length))
        |> Enum.with_index(1)
        |> Enum.each(fn {elem, idx} ->
          case elem do
            nil -> delete_assessment_config(%{course_id: course_id, order: idx})
            elem -> insert_or_update_assessment_config(elem)
          end
        end)
      else
        false -> {:error, {:bad_request, "Invalid parameter(s)"}}
      end
    end
  end

  def insert_or_update_assessment_config(params = %{course_id: course_id, order: order}) do
    AssessmentConfig
    |> where(course_id: ^course_id)
    |> where(order: ^order)
    |> Repo.one()
    |> case do
      nil -> AssessmentConfig.changeset(%AssessmentConfig{}, params)
      at -> AssessmentConfig.changeset(at, params)
    end
    |> Repo.insert_or_update()
  end

  @spec delete_assessment_config(map()) ::
          {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()} | {:error, :no_such_enrty}
  def delete_assessment_config(params = %{course_id: course_id, order: order}) do
    AssessmentConfig
    |> where(course_id: ^course_id)
    |> where(order: ^order)
    |> Repo.one()
    |> case do
      nil -> {:error, :no_such_enrty}
      at -> AssessmentConfig.changeset(at, params) |> Repo.delete()
    end
  end

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
  # Reassign a student to a discussion group
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
  # def list_students_by_leader(staff = %CourseRegistration{}) do
  #   import Cadet.Course.Query, only: [group_members: 1]

  #   staff
  #   |> group_members()
  #   |> Repo.all()
  #   |> Repo.preload([:student])
  # end

  @upload_file_roles ~w(admin staff)a

  @doc """
  Upload a sourcecast file.

  Note that there are no checks for whether the user belongs to the course, as this has been checked
  inside a plug in the router.
  """
  def upload_sourcecast_file(
        _inserter = %CourseRegistration{user_id: user_id, course_id: course_id, role: role},
        attrs = %{}
      ) do
    if role in @upload_file_roles do
      course_reg =
        CourseRegistration
        |> where(user_id: ^user_id)
        |> where(course_id: ^course_id)
        |> preload(:course)
        |> preload(:user)
        |> Repo.one()

      changeset =
        %Sourcecast{}
        |> Sourcecast.changeset(attrs)
        |> put_assoc(:uploader, course_reg.user)
        |> put_assoc(:course, course_reg.course)

      case Repo.insert(changeset) do
        {:ok, sourcecast} ->
          {:ok, sourcecast}

        {:error, changeset} ->
          {:error, {:bad_request, full_error_messages(changeset)}}
      end
    else
      {:error, {:forbidden, "User is not permitted to upload"}}
    end
  end

  @doc """
  Upload a public sourcecast file.

  Note that there are no checks for whether the user belongs to the course, as this has been checked
  inside a plug in the router.
  """
  def upload_sourcecast_file_public(
        inserter,
        _inserter_course_reg = %CourseRegistration{role: role},
        attrs = %{}
      ) do
    if role in @upload_file_roles do
      changeset =
        %Sourcecast{}
        |> Sourcecast.changeset(attrs)
        |> put_assoc(:uploader, inserter)

      case Repo.insert(changeset) do
        {:ok, sourcecast} ->
          {:ok, sourcecast}

        {:error, changeset} ->
          {:error, {:bad_request, full_error_messages(changeset)}}
      end
    else
      {:error, {:forbidden, "User is not permitted to upload"}}
    end
  end

  @doc """
  Delete a sourcecast file

  Note that there are no checks for whether the user belongs to the course, as this has been checked
  inside a plug in the router.
  """
  def delete_sourcecast_file(_deleter = %CourseRegistration{role: role}, sourcecast_id) do
    if role in @upload_file_roles do
      sourcecast = Repo.get(Sourcecast, sourcecast_id)
      SourcecastUpload.delete({sourcecast.audio, sourcecast})
      Repo.delete(sourcecast)
    else
      {:error, {:forbidden, "User is not permitted to delete"}}
    end
  end

  @doc """
  Get sourcecast files
  """
  def get_sourcecast_files(course_id) when is_ecto_id(course_id) do
    Sourcecast
    |> where(course_id: ^course_id)
    |> Repo.all()
    |> Repo.preload(:uploader)
  end

  def get_sourcecast_files do
    Sourcecast
    # Public sourcecasts are those without course_id
    |> where([s], is_nil(s.course_id))
    |> Repo.all()
    |> Repo.preload(:uploader)
  end
end
