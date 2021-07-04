defmodule Cadet.Courses do
  @moduledoc """
  Courses context contains domain logic for Course administration
  management such as course configuration, discussion groups and materials
  """
  use Cadet, [:context, :display]

  import Ecto.Query
  alias Ecto.Multi

  alias Cadet.Accounts.{CourseRegistration, User}

  alias Cadet.Courses.{
    AssessmentConfig,
    Course,
    Group,
    Sourcecast,
    SourcecastUpload
  }

  @doc """
  Creates a new course configuration, course registration, and sets
  the user's latest course id to the newly created course.
  """
  def create_course_config(params, user) do
    Multi.new()
    |> Multi.insert(:course, Course.changeset(%Course{}, params))
    |> Multi.insert(:course_reg, fn %{course: course} ->
      CourseRegistration.changeset(%CourseRegistration{}, %{
        course_id: course.id,
        user_id: user.id,
        role: :admin
      })
    end)
    |> Multi.update(:latest_viewed_id, fn %{course: course} ->
      User
      |> where(id: ^user.id)
      |> Repo.one()
      |> User.changeset(%{latest_viewed_id: course.id})
    end)
    |> Repo.transaction()
  end

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
          {:ok, %Course{}} | {:error, Ecto.Changeset.t()} | {:error, {:bad_request, String.t()}}
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

  def mass_upsert_and_reorder_assessment_configs(course_id, configs) do
    if is_list(configs) do
      configs_length = configs |> length()

      with true <- configs_length <= 8,
           true <- configs_length >= 1 do
        new_configs =
          configs
          |> Enum.map(fn elem ->
            {:ok, config} = insert_or_update_assessment_config(course_id, elem)
            Map.put(elem, :assessment_config_id, config.id)
          end)

        reorder_assessment_configs(course_id, new_configs)
      else
        false -> {:error, {:bad_request, "Invalid parameter(s)"}}
      end
    else
      {:error, {:bad_request, "Invalid parameter(s)"}}
    end
  end

  def insert_or_update_assessment_config(
        course_id,
        params = %{assessment_config_id: assessment_config_id}
      ) do
    AssessmentConfig
    |> where(course_id: ^course_id)
    |> where(id: ^assessment_config_id)
    |> Repo.one()
    |> case do
      nil ->
        AssessmentConfig.changeset(%AssessmentConfig{}, Map.put(params, :course_id, course_id))

      at ->
        AssessmentConfig.changeset(at, params)
    end
    |> Repo.insert_or_update()
  end

  defp update_assessment_config(
         course_id,
         params = %{assessment_config_id: assessment_config_id}
       ) do
    AssessmentConfig
    |> where(course_id: ^course_id)
    |> where(id: ^assessment_config_id)
    |> Repo.one()
    |> case do
      nil -> {:error, :no_such_entry}
      at -> at |> AssessmentConfig.changeset(params) |> Repo.update()
    end
  end

  def reorder_assessment_configs(course_id, configs) do
    Repo.transaction(fn ->
      configs
      |> Enum.each(fn elem ->
        update_assessment_config(course_id, Map.put(elem, :order, nil))
      end)

      configs
      |> Enum.with_index(1)
      |> Enum.each(fn {elem, idx} ->
        update_assessment_config(course_id, Map.put(elem, :order, idx))
      end)
    end)
  end

  @spec delete_assessment_config(integer(), map()) ::
          {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()} | {:error, :no_such_enrty}
  def delete_assessment_config(course_id, params = %{assessment_config_id: assessment_config_id}) do
    AssessmentConfig
    |> where(course_id: ^course_id)
    |> where(id: ^assessment_config_id)
    |> Repo.one()
    |> case do
      nil -> {:error, :no_such_enrty}
      at -> at |> AssessmentConfig.changeset(params) |> Repo.delete()
    end
  end

  def upsert_groups_in_course(usernames_and_groups, course_id) do
    usernames_and_groups
    |> Enum.reduce_while(nil, fn %{username: username} = entry, _acc ->
      with {:ok, groupname} <- Map.fetch(entry, :group) do
        case upsert_groups_in_course_helper(username, course_id, groupname) do
          {:ok, _} -> {:cont, :ok}
          {:error, changeset} -> {:halt, {:error, {:bad_request, full_error_messages(changeset)}}}
        end
      else
        # If no group is specified, continue reduction
        :error -> {:cont, :ok}
      end
    end)
  end

  defp upsert_groups_in_course_helper(username, course_id, groupname) do
    with {:get_group, {:ok, group}} <- {:get_group, get_or_create_group(groupname, course_id)},
         {:get_course_reg, %{role: role} = course_reg} <-
           {:get_course_reg,
            CourseRegistration
            |> where(
              user_id: ^(User |> where(username: ^username) |> Repo.one() |> Map.fetch!(:id))
            )
            |> where(course_id: ^course_id)
            |> Repo.one()} do
      # It is ok to assume that user course registions already exist, as they would have been created
      # in the admin_user_controller before calling this function
      case role do
        # If student, update his course registration
        :student ->
          course_reg
          |> CourseRegistration.changeset(%{group_id: group.id})
          |> Repo.update()

        # If admin or staff, set them as group leader
        _ ->
          group
          |> Group.changeset(%{leader_id: course_reg.id})
          |> Repo.update()
      end
    end
  end

  @doc """
  Get a group based on the group name and course id or create one if it doesn't exist
  """
  @spec get_or_create_group(String.t(), integer()) ::
          {:ok, %Group{}} | {:error, Ecto.Changeset.t()}
  def get_or_create_group(name, course_id) when is_binary(name) and is_ecto_id(course_id) do
    Group
    |> where(name: ^name)
    |> where(course_id: ^course_id)
    |> Repo.one()
    |> case do
      nil ->
        %Group{}
        |> Group.changeset(%{name: name, course_id: course_id})
        |> Repo.insert()

      group ->
        {:ok, group}
    end
  end

  # @doc """
  # Updates a group based on the group name or create one if it doesn't exist
  # """
  # @spec insert_or_update_group(map()) :: {:ok, %Group{}} | {:error, Ecto.Changeset.t()}
  # def insert_or_update_group(params = %{name: name}) when is_binary(name) do
  #   Group
  #   |> where(name: ^name)
  #   |> Repo.one()
  #   |> case do
  #     nil ->
  #       Group.changeset(%Group{}, params)

  #     group ->
  #       Group.changeset(group, params)
  #   end
  #   |> Repo.insert_or_update()
  # end

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
