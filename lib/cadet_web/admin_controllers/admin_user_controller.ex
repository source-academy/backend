defmodule CadetWeb.AdminUserController do
  use CadetWeb, :controller
  use PhoenixSwagger

  import Ecto.Query

  alias Cadet.Repo
  alias Cadet.{Accounts, Assessments, Courses}
  alias Cadet.Accounts.{CourseRegistrations, CourseRegistration, Role}

  # This controller is used to find all users of a course

  def index(conn, filter) do
    users =
      filter |> try_keywordise_string_keys() |> Accounts.get_users_by(conn.assigns.course_reg)

    render(conn, "users.json", users: users)
  end

  def combined_total_xp(conn, %{"course_reg_id" => course_reg_id}) do
    course_reg = Repo.get(CourseRegistration, course_reg_id)

    course_id = course_reg.course_id
    user_id = course_reg.user_id
    course_reg_id = course_reg.id

    total_xp = Assessments.user_total_xp(course_id, user_id, course_reg_id)
    json(conn, %{totalXp: total_xp})
  end

  @add_users_role ~w(admin)a
  def upsert_users_and_groups(conn, %{
        "course_id" => course_id,
        "users" => usernames_roles_groups,
        "provider" => provider
      }) do
    %{role: admin_role} = conn.assigns.course_reg
    usernames_roles_groups = usernames_roles_groups |> Enum.map(&to_snake_case_atom_keys/1)

    with {:validate_cap, true} <-
           {:validate_cap,
            Enum.count(CourseRegistrations.get_users(course_id) ++ usernames_roles_groups) <= 1500},
         {:validate_role, true} <- {:validate_role, admin_role in @add_users_role},
         {:validate_provider, true} <-
           {:validate_provider,
            Map.has_key?(Application.get_env(:cadet, :identity_providers, %{}), provider)},
         {:validate_usernames, true} <-
           {:validate_usernames,
            Enum.all?(usernames_roles_groups, fn x ->
              Map.has_key?(x, :username) and is_binary(x.username) and x.username != ""
            end)},
         {:validate_roles, true} <-
           {:validate_roles,
            Enum.all?(usernames_roles_groups, fn x ->
              Map.has_key?(x, :role) and String.to_atom(x.role) in Role.__enums__()
            end)} do
      {:ok, conn} =
        Repo.transaction(
          fn ->
            with {:upsert_users, :ok} <-
                   {:upsert_users,
                    CourseRegistrations.upsert_users_in_course(
                      provider,
                      usernames_roles_groups,
                      course_id
                    )},
                 {:upsert_groups, :ok} <-
                   {:upsert_groups,
                    Courses.upsert_groups_in_course(usernames_roles_groups, course_id, provider)} do
              text(conn, "OK")
            else
              {:upsert_users, {:error, {status, message}}} ->
                conn |> put_status(status) |> text(message)

              {:upsert_groups, {:error, {status, message}}} ->
                conn |> put_status(status) |> text(message)
            end
          end,
          timeout: 20_000
        )

      conn
    else
      {:validate_cap, false} ->
        conn |> put_status(:bad_request) |> text("A course can have maximum of 1500 users")

      {:validate_role, false} ->
        conn |> put_status(:forbidden) |> text("User is not permitted to add users")

      {:validate_provider, false} ->
        conn |> put_status(:bad_request) |> text("Invalid authentication provider")

      {:validate_usernames, false} ->
        conn |> put_status(:bad_request) |> text("Invalid username(s) provided")

      {:validate_roles, false} ->
        conn |> put_status(:bad_request) |> text("Invalid role(s) provided")
    end
  end

  @update_role_roles ~w(admin)a
  def update_role(conn, %{"role" => role, "course_reg_id" => course_reg_id}) do
    course_reg_id = course_reg_id |> String.to_integer()

    %{id: admin_course_reg_id, role: admin_role, course_id: admin_course_id} =
      conn.assigns.course_reg

    with {:validate_role, true} <- {:validate_role, admin_role in @update_role_roles},
         {:validate_not_self, true} <- {:validate_not_self, admin_course_reg_id != course_reg_id},
         {:get_cr, user_course_reg} when not is_nil(user_course_reg) <-
           {:get_cr, CourseRegistration |> where(id: ^course_reg_id) |> Repo.one()},
         {:validate_same_course, true} <-
           {:validate_same_course, user_course_reg.course_id == admin_course_id} do
      case CourseRegistrations.update_role(role, course_reg_id) do
        {:ok, %{}} ->
          text(conn, "OK")

        {:error, {status, message}} ->
          conn
          |> put_status(status)
          |> text(message)
      end
    else
      {:validate_role, false} ->
        conn |> put_status(:forbidden) |> text("User is not permitted to change others' roles")

      {:validate_not_self, false} ->
        conn |> put_status(:bad_request) |> text("Admin not allowed to downgrade own role")

      {:get_cr, _} ->
        conn |> put_status(:bad_request) |> text("User course registration does not exist")

      {:validate_same_course, false} ->
        conn |> put_status(:forbidden) |> text("User is in a different course")
    end
  end

  @delete_user_roles ~w(admin)a
  def delete_user(conn, %{"course_reg_id" => course_reg_id}) do
    course_reg_id = course_reg_id |> String.to_integer()

    %{id: admin_course_reg_id, role: admin_role, course_id: admin_course_id} =
      conn.assigns.course_reg

    with {:validate_role, true} <- {:validate_role, admin_role in @delete_user_roles},
         {:validate_not_self, true} <- {:validate_not_self, admin_course_reg_id != course_reg_id},
         {:get_cr, user_course_reg} when not is_nil(user_course_reg) <-
           {:get_cr, CourseRegistration |> where(id: ^course_reg_id) |> Repo.one()},
         {:prevent_delete_admin, true} <- {:prevent_delete_admin, user_course_reg.role != :admin},
         {:validate_same_course, true} <-
           {:validate_same_course, user_course_reg.course_id == admin_course_id} do
      case CourseRegistrations.delete_course_registration(course_reg_id) do
        {:ok, %{}} ->
          text(conn, "OK")

        {:error, {status, message}} ->
          conn
          |> put_status(status)
          |> text(message)
      end
    else
      {:validate_role, false} ->
        conn |> put_status(:forbidden) |> text("User is not permitted to delete other users")

      {:validate_not_self, false} ->
        conn
        |> put_status(:bad_request)
        |> text("Admin not allowed to delete ownself from course")

      {:get_cr, _} ->
        conn |> put_status(:bad_request) |> text("User course registration does not exist")

      {:prevent_delete_admin, false} ->
        conn |> put_status(:bad_request) |> text("Admins cannot be deleted")

      {:validate_same_course, false} ->
        conn |> put_status(:forbidden) |> text("User is in a different course")
    end
  end

  swagger_path :index do
    get("/v2/courses/{course_id}/admin/users")

    summary("Returns a list of users in the course owned by the admin")

    security([%{JWT: []}])
    produces("application/json")
    response(200, "OK", Schema.ref(:AdminUserInfo))
    response(401, "Unauthorised")
  end

  swagger_path :combined_total_xp do
    get("/v2/courses/{course_id}/admin/users/{course_reg_id}/total_xp")

    summary("Get the specified user's total XP from achievements and assessments")

    security([%{JWT: []}])
    produces("application/json")

    parameters do
      course_id(:path, :integer, "Course ID", required: true)
      course_reg_id(:path, :integer, "Course registration ID", required: true)
    end

    response(200, "OK", Schema.ref(:TotalXPInfo))
    response(401, "Unauthorised")
  end

  swagger_path :add_users do
    put("/v2/courses/{course_id}/admin/users")

    summary("Adds the list of usernames and roles to the course")
    security([%{JWT: []}])
    consumes("application/json")

    parameters do
      course_id(:path, :integer, "Course ID", required: true)
      users(:body, Schema.array(:UsernameAndRole), "Array of usernames and roles", required: true)

      provider(:body, :string, "The authentication provider linked to these usernames",
        required: true
      )
    end

    response(200, "OK")
    response(400, "Bad Request. Invalid provider, username or role")
    response(403, "Forbidden. You are not an admin")
  end

  swagger_path :update_role do
    put("/v2/courses/{course_id}/admin/users/role")

    summary("Updates the role of the given user in the the course")
    security([%{JWT: []}])
    consumes("application/json")

    parameters do
      course_id(:path, :integer, "Course ID", required: true)
      role(:body, :role, "The new role", required: true)

      courseRegId(
        :body,
        :integer,
        "The course registration of the user whose role is to be updated",
        required: true
      )
    end

    response(200, "OK")

    response(
      400,
      "Bad Request. User course registration does not exist or admin not allowed to downgrade own role"
    )

    response(403, "Forbidden. User is in different course, or you are not an admin")
  end

  swagger_path :delete_user do
    delete("/v2/courses/{course_id}/admin/users")

    summary("Deletes a user from a course")
    consumes("application/json")

    parameters do
      course_id(:path, :integer, "Course ID", required: true)

      courseRegId(
        :body,
        :integer,
        "The course registration of the user whose role is to be updated",
        required: true
      )
    end

    response(200, "OK")

    response(
      400,
      "Bad Request. User course registration does not exist or admin not allowed to delete ownself from course or admins cannot be deleted"
    )

    response(403, "Forbidden. User is in different course, or you are not an admin")
  end

  def swagger_definitions do
    %{
      AdminUserInfo:
        swagger_schema do
          title("User")
          description("Basic information about the user in this course")

          properties do
            userId(:integer, "User's ID")
            name(:string, "Full name of the user")

            role(
              :string,
              "Role of the user in this course. Can be 'student', 'staff', or 'admin'"
            )

            group(
              :string,
              "Group the user belongs to in this course. May be null if the user does not belong to any group"
            )
          end
        end,
      UsernameAndRole:
        swagger_schema do
          title("Username and role")
          description("Username and role of the user to add to this course")

          properties do
            username(:string, "The user's username")
            role(:role, "The user's role. Can be 'student', 'staff', or 'admin'")
          end
        end
    }
  end

  def combined_user_total_xp(conn, _) do
    combined_user_xp_total_query = """
    SELECT
      name,
      username,
      assessment_xp,
      achievement_xp
    FROM
      (SELECT
        sum(total_xp) as assessment_xp,
        users.name,
        users.username,
        total_xps.cr_id
      FROM
        (
          SELECT
            sum(sa1."xp") + sum(sa1."xp_adjustment") + max(ss0."xp_bonus") AS "total_xp",
            ss0."student_id" as cr_id,
            ss0.user_id
          FROM
            (
              SELECT
                submissions.xp_bonus,
                submissions.student_id,
                submissions.id,
                cr_ids.user_id
              FROM
                submissions
                INNER JOIN (
                  SELECT
                    cr.id as id,
                    cr.user_id
                  FROM
                    course_registrations cr
                  WHERE
                    cr.course_id = 41
                ) cr_ids on cr_ids.id = submissions.student_id
            ) as ss0
            INNER JOIN "answers" sa1 ON ss0."id" = sa1."submission_id"
          GROUP BY
            ss0."id",
            ss0."student_id",
            ss0."user_id"
        ) total_xps
        inner join users on users.id = total_xps.user_id
      GROUP BY
        username,
        cr_id,
        name) as total_assessments
    LEFT JOIN
      (SELECT
        sum(s0."xp") as achievement_xp,
        s0."course_reg_id" as cr_id
      FROM
        (
          SELECT
            CASE WHEN bool_and(is_variable_xp) THEN SUM(count) ELSE MAX(xp) END AS "xp",
            sg3."course_reg_id" AS "course_reg_id"
          FROM
            "achievements" AS sa0
            INNER JOIN "achievement_to_goal" AS sa1 ON sa1."achievement_uuid" = sa0."uuid"
            INNER JOIN "goals" AS sg2 ON sg2."uuid" = sa1."goal_uuid"
            RIGHT OUTER JOIN "goal_progress" AS sg3 ON (sg3."goal_uuid" = sg2."uuid")
          WHERE
            (sa0."course_id" = 41)
          GROUP BY
            sa0."uuid",
            sg3."course_reg_id"
          HAVING
            (
              bool_and(
                (
                  sg3."completed"
                  AND (sg3."count" >= sg2."target_count")
                )
                AND NOT (sg3."course_reg_id" IS NULL)
              )
            )
        ) AS s0
      GROUP BY s0."course_reg_id") as total_achievement
    ON total_assessments."cr_id" = total_achievement."cr_id"
    """

    all_users_total_xp = Ecto.Adapters.SQL.query!(Repo, combined_user_xp_total_query)
    json(conn, %{all_users_xp: all_users_total_xp.rows})
  end

  swagger_path :all_users_combined_total_xp do
    get("/courses/{courseId}/admin/users/total_xp")

    summary("Get the total xp from achievements and assessments of all users in a specific course")

    security([%{JWT: []}])
    produces("application/json")

    parameters do
      courseId(:path, :integer, "Course Id", required: true)
    end

    response(200, "OK", Schema.ref(:TotalXPInfo))
    response(401, "Unauthorised")
  end
end
