defmodule Cadet.Courses do
  @moduledoc """
  Courses context contains domain logic for Course administration
  management such as course configuration, discussion groups and materials
  """
  use Cadet, [:context, :display]

  import Ecto.Query

  alias Cadet.Accounts.User

  alias Cadet.Courses.{
    AssessmentConfig,
    AssessmentTypes,
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
        assessment_types =
          AssessmentTypes
          |> where(course_id: ^course_id)
          |> Repo.all()
          |> Enum.sort(&(&1.order < &2.order))
          |> Enum.map(& &1.type)

        {:ok, Map.put_new(course, :assessment_types, assessment_types)}
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

  @doc """
  Updates the assessment configuration for the specified course
  """
  @spec update_assessment_config(integer, integer, integer, integer) ::
          {:ok, %AssessmentConfig{}} | {:error, Ecto.Changeset.t()}
  def update_assessment_config(course_id, early_xp, hours_before_decay, decay_rate) do
    AssessmentConfig
    |> where(course_id: ^course_id)
    |> Repo.one()
    |> AssessmentConfig.changeset(%{
      early_submission_xp: early_xp,
      hours_before_early_xp_decay: hours_before_decay,
      decay_rate_points_per_hour: decay_rate
    })
    |> Repo.update()
  end

  @doc """
  Updates the Assessment Types for the specified course
  """
  @spec update_assessment_types(integer, list()) :: :ok | {:error, {:bad_request, String.t()}}
  def update_assessment_types(course_id, params) do
    if not is_list(params) do
      {:error, {:bad_request, "Invalid parameter(s)"}}
    else
      params_length = params |> length()

      with true <- params_length <= 5,
           true <- params_length >= 1,
           true <- params |> Enum.reduce(true, fn elem, acc -> acc and is_binary(elem) end),
           true <-
             params |> Enum.map(fn elem -> String.capitalize(elem) end) |> Enum.uniq() |> length() ===
               params_length do
        (params ++ List.duplicate(nil, 5 - params_length))
        |> Enum.with_index(1)
        |> Enum.each(fn {elem, idx} ->
          case elem do
            nil ->
              AssessmentTypes
              |> where(course_id: ^course_id)
              |> where(order: ^idx)
              |> Repo.delete_all()

            _ ->
              AssessmentTypes.changeset(%AssessmentTypes{}, %{
                course_id: course_id,
                order: idx,
                type: elem
              })
              |> Repo.insert(
                on_conflict: {:replace, [:type]},
                conflict_target: [:course_id, :order]
              )
          end
        end)
      else
        false ->
          {:error, {:bad_request, "Invalid parameter(s)"}}
      end
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
  # def list_students_by_leader(staff = %User{}) do
  #   import Cadet.Course.Query, only: [group_members: 1]

  #   staff
  #   |> group_members()
  #   |> Repo.all()
  #   |> Repo.preload([:student])
  # end

  @upload_file_roles ~w(admin staff)a

  @doc """
  Upload a sourcecast file
  """
  def upload_sourcecast_file(uploader = %User{role: role}, attrs = %{}) do
    if role in @upload_file_roles do
      changeset =
        %Sourcecast{}
        |> Sourcecast.changeset(attrs)
        |> put_assoc(:uploader, uploader)

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
  """
  def delete_sourcecast_file(_deleter = %User{role: role}, id) do
    if role in @upload_file_roles do
      sourcecast = Repo.get(Sourcecast, id)
      SourcecastUpload.delete({sourcecast.audio, sourcecast})
      Repo.delete(sourcecast)
    else
      {:error, {:forbidden, "User is not permitted to delete"}}
    end
  end
end
