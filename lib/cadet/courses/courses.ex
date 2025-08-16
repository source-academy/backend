defmodule Cadet.Courses do
  @moduledoc """
  Courses context contains domain logic for Course administration
  management such as course configuration, discussion groups and materials
  """
  use Cadet, [:context, :display]

  import Ecto.Query
  require Logger
  alias Ecto.Multi

  alias Cadet.Accounts.{CourseRegistration, User, CourseRegistrations}

  alias Cadet.Courses.{
    AssessmentConfig,
    Course,
    Group,
    Sourcecast,
    SourcecastUpload
  }

  alias Cadet.Assessments
  alias Cadet.Assessments.Assessment
  alias Cadet.Assets.Assets

  @doc """
  Creates a new course configuration, course registration, and sets
  the user's latest course id to the newly created course.
  """
  def create_course_config(params, user) do
    Logger.info("Creating new course configuration for user #{user.id}")

    result =
      Multi.new()
      |> Multi.insert(:course, Course.changeset(%Course{}, params))
      |> Multi.run(:course_reg, fn _repo, %{course: course} ->
        CourseRegistrations.enroll_course(%{
          course_id: course.id,
          user_id: user.id,
          role: :admin
        })
      end)
      |> Repo.transaction()

    case result do
      {:ok, %{course: course}} ->
        Logger.info("Successfully created course #{course.id} for user #{user.id}")

      {:error, _operation, changeset, _changes} ->
        Logger.error(
          "Failed to create course for user #{user.id}: #{full_error_messages(changeset)}"
        )
    end

    result
  end

  @doc """
  Returns the course configuration for the specified course.
  """
  @spec get_course_config(integer) ::
          {:ok, Course.t()} | {:error, {:bad_request, String.t()}}
  def get_course_config(course_id) when is_ecto_id(course_id) do
    Logger.info("Retrieving course configuration for course #{course_id}")

    case retrieve_course(course_id) do
      nil ->
        Logger.error("Course #{course_id} not found")
        {:error, {:bad_request, "Invalid course id"}}

      course ->
        assessment_configs =
          AssessmentConfig
          |> where(course_id: ^course_id)
          |> Repo.all()
          |> Enum.sort(&(&1.order < &2.order))
          |> Enum.map(& &1.type)

        Logger.info("Successfully retrieved course configuration for course #{course_id}")
        {:ok, Map.put_new(course, :assessment_configs, assessment_configs)}
    end
  end

  @doc """
  Updates the general course configuration for the specified course
  """
  @spec update_course_config(integer, %{}) ::
          {:ok, Course.t()} | {:error, Ecto.Changeset.t()} | {:error, {:bad_request, String.t()}}
  def update_course_config(course_id, params) when is_ecto_id(course_id) do
    Logger.info("Updating course configuration for course #{course_id}")

    case retrieve_course(course_id) do
      nil ->
        Logger.error("Cannot update course #{course_id} - course not found")
        {:error, {:bad_request, "Invalid course id"}}

      course ->
        if Map.has_key?(params, :viewable) and not params.viewable do
          remove_latest_viewed_course_id(course_id)
        end

        result =
          course
          |> Course.changeset(params)
          |> Repo.update()

        case result do
          {:ok, _} ->
            Logger.info("Successfully updated course configuration for course #{course_id}")

          {:error, changeset} ->
            Logger.error(
              "Failed to update course configuration for course #{course_id}: #{full_error_messages(changeset)}"
            )
        end

        result
    end
  end

  def get_all_course_ids do
    Course
    |> select([c], c.id)
    |> Repo.all()
  end

  defp retrieve_course(course_id) when is_ecto_id(course_id) do
    Course
    |> where(id: ^course_id)
    |> Repo.one()
  end

  defp remove_latest_viewed_course_id(course_id) do
    User
    |> where(latest_viewed_course_id: ^course_id)
    |> Repo.all()
    |> Enum.each(fn user ->
      user
      |> User.changeset(%{latest_viewed_course_id: nil})
      |> Repo.update()
    end)
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

  @spec delete_assessment_config(integer(), integer()) ::
          {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()} | {:error, :no_such_enrty}
  def delete_assessment_config(course_id, assessment_config_id) do
    config =
      AssessmentConfig
      |> where(course_id: ^course_id)
      |> where(id: ^assessment_config_id)
      |> Repo.one()

    case config do
      nil ->
        {:error, "The given assessment configuration does not exist"}

      config ->
        Assessment
        |> where(config_id: ^config.id)
        |> Repo.all()
        |> Enum.each(fn assessment -> Assessments.delete_assessment(assessment.id) end)

        Repo.delete(config)
    end
  end

  def upsert_groups_in_course(usernames_and_groups, course_id, provider) do
    usernames_and_groups
    |> Enum.reduce_while(nil, fn %{username: username} = entry, _acc ->
      entry
      |> Map.fetch(:group)
      |> case do
        {:ok, groupname} ->
          # Add users to group
          upsert_groups_in_course_helper(username, course_id, groupname, provider)

        :error ->
          # Delete users from group
          upsert_groups_in_course_helper(username, course_id, provider)
      end
      |> case do
        {:ok, _} -> {:cont, :ok}
        {:error, changeset} -> {:halt, {:error, {:bad_request, full_error_messages(changeset)}}}
      end
    end)
  end

  defp upsert_groups_in_course_helper(username, course_id, groupname, provider) do
    with {:get_group, {:ok, group}} <- {:get_group, get_or_create_group(groupname, course_id)},
         {:get_course_reg, %{role: role} = course_reg} <-
           {:get_course_reg,
            CourseRegistration
            |> where(
              user_id:
                ^(User
                  |> where(username: ^username, provider: ^provider)
                  |> Repo.one()
                  |> Map.fetch!(:id))
            )
            |> where(course_id: ^course_id)
            |> Repo.one()} do
      # It is ok to assume that user course registions already exist, as they would
      # have been created in the admin_user_controller before calling this function
      case role do
        # If student, update his course registration
        :student ->
          update_course_reg_group(course_reg, group.id)

        # If admin or staff, remove their previous group assignment and set them as group leader
        _ ->
          if group.leader_id != course_reg.id do
            update_course_reg_group(course_reg, group.id)
            remove_staff_from_group(course_id, course_reg.id)

            group
            |> Group.changeset(%{leader_id: course_reg.id})
            |> Repo.update()
          else
            {:ok, nil}
          end
      end
    end
  end

  defp upsert_groups_in_course_helper(username, course_id, provider) do
    with {:get_course_reg, %{role: role} = course_reg} <-
           {:get_course_reg,
            CourseRegistration
            |> where(
              user_id:
                ^(User
                  |> where(username: ^username, provider: ^provider)
                  |> Repo.one()
                  |> Map.fetch!(:id))
            )
            |> where(course_id: ^course_id)
            |> Repo.one()} do
      case role do
        :student ->
          update_course_reg_group(course_reg, nil)

        _ ->
          remove_staff_from_group(course_id, course_reg.id)
          update_course_reg_group(course_reg, nil)
          {:ok, nil}
      end
    end
  end

  defp remove_staff_from_group(course_id, leader_id) do
    Group
    |> where(course_id: ^course_id)
    |> where(leader_id: ^leader_id)
    |> Repo.one()
    |> case do
      nil ->
        nil

      group ->
        group
        |> Group.changeset(%{leader_id: nil})
        |> Repo.update()
    end
  end

  defp update_course_reg_group(course_reg, group_id) do
    course_reg
    |> CourseRegistration.changeset(%{group_id: group_id})
    |> Repo.update()
  end

  @doc """
  Get a group based on the group name and course id or create one if it doesn't exist
  """
  @spec get_or_create_group(String.t(), integer()) ::
          {:ok, Group.t()} | {:error, Ecto.Changeset.t()}
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

  @doc """
  Upload a sourcecast file.

  Note that there are no checks for whether the user belongs to the course,
  as this has been checked inside a plug in the router.
  """
  def upload_sourcecast_file(
        _inserter = %CourseRegistration{user_id: user_id, course_id: course_id},
        attrs = %{}
      ) do
    Logger.info("Uploading sourcecast file for user #{user_id} in course #{course_id}")

    changeset =
      Sourcecast.changeset(%Sourcecast{uploader_id: user_id, course_id: course_id}, attrs)

    case Repo.insert(changeset) do
      {:ok, sourcecast} ->
        Logger.info("Successfully uploaded sourcecast #{sourcecast.id} for user #{user_id}")
        {:ok, sourcecast}

      {:error, changeset} ->
        Logger.error(
          "Failed to upload sourcecast for user #{user_id}: #{full_error_messages(changeset)}"
        )

        {:error, {:bad_request, full_error_messages(changeset)}}
    end
  end

  # @doc """
  # Upload a public sourcecast file.

  # Note that there are no checks for whether the user belongs to the course,
  # as this has been checked inside a plug in the router.
  # unused in the current version
  # """
  # def upload_sourcecast_file_public(
  #       inserter,
  #       _inserter_course_reg = %CourseRegistration{role: role},
  #       attrs = %{}
  #     ) do
  #   if role in @upload_file_roles do
  #     changeset =
  #       %Sourcecast{}
  #       |> Sourcecast.changeset(attrs)
  #       |> put_assoc(:uploader, inserter)

  #     case Repo.insert(changeset) do
  #       {:ok, sourcecast} ->
  #         {:ok, sourcecast}

  #       {:error, changeset} ->
  #         {:error, {:bad_request, full_error_messages(changeset)}}
  #     end
  #   else
  #     {:error, {:forbidden, "User is not permitted to upload"}}
  #   end
  # end

  @doc """
  Delete a sourcecast file

  Note that there are no checks for whether the user belongs to the course, as this has been checked
  inside a plug in the router.
  """
  def delete_sourcecast_file(sourcecast_id) do
    Logger.info("Deleting sourcecast file #{sourcecast_id}")

    sourcecast = Repo.get(Sourcecast, sourcecast_id)

    case sourcecast do
      nil ->
        Logger.error("Sourcecast #{sourcecast_id} not found")
        {:error, {:not_found, "Sourcecast not found!"}}

      sourcecast ->
        SourcecastUpload.delete({sourcecast.audio, sourcecast})
        result = Repo.delete(sourcecast)

        case result do
          {:ok, _} ->
            Logger.info("Successfully deleted sourcecast #{sourcecast_id}")

          {:error, changeset} ->
            Logger.error(
              "Failed to delete sourcecast #{sourcecast_id}: #{full_error_messages(changeset)}"
            )
        end

        result
    end
  end

  @doc """
  Get sourcecast files
  """
  def get_sourcecast_files(course_id) when is_ecto_id(course_id) do
    Logger.info("Retrieving sourcecast files for course #{course_id}")

    sourcecasts =
      Sourcecast
      |> where(course_id: ^course_id)
      |> Repo.all()
      |> Repo.preload(:uploader)

    Logger.info("Retrieved #{length(sourcecasts)} sourcecast files for course #{course_id}")
    sourcecasts
  end

  # unused in the current version
  # def get_sourcecast_files do
  #   Sourcecast
  #   # Public sourcecasts are those without course_id
  #   |> where([s], is_nil(s.course_id))
  #   |> Repo.all()
  #   |> Repo.preload(:uploader)
  # end

  @spec assets_prefix(Course.t()) :: binary()
  def assets_prefix(course) do
    course.assets_prefix || "#{Assets.assets_prefix()}#{course.id}/"
  end
end
