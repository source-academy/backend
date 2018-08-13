defmodule Mix.Tasks.GroupUploader do
  use Mix.Task

  require Logger

  alias Cadet.{Accounts, Course}

  @moduledoc """
  Mix Task to upload the tutorial groups and it's
  participants
  """

  def run([groups_arg | [avengers_arg | _]]) do
    Mix.Task.run("app.start")

    # Getting only the groups from the excel file
    groups =
      groups_arg
      |> Xlsxir.multi_extract()
      |> Keyword.get(:ok)
      |> Xlsxir.get_list()
      |> Enum.drop(3)

    # Getting the avenger-mentor-studio relation from the excel file
    avengers =
      avengers_arg
      |> Xlsxir.multi_extract()
      |> Keyword.get(:ok)
      |> Xlsxir.get_list()
      |> Enum.drop(1)

    upload_to_database(groups, avengers, nil)
  end

  def run(_), do: Logger.error("Invalid arguments")

  defp upload_to_database([row | rows], avengers, current_group) do
    cond do
      # End of excel sheet
      row == nil || List.first(row) == "//" ->
        Logger.info("Task completed")

      # Row with tutorial name
      String.contains?(List.first(row), "Total Students") ->
        # Get avenger for that particular tutorial
        [current_avenger_name | [current_avenger_id | [_ | [mentor_name | [mentor_id | _]]]]] =
          List.first(avengers)

        {:ok, avenger} =
          Accounts.get_or_create_user(
            current_avenger_name,
            :staff,
            current_avenger_id
          )

        {:ok, mentor} =
          Accounts.get_or_create_user(
            mentor_name,
            :staff,
            mentor_id
          )

        # Get group name from row
        group_name =
          String.slice(List.first(row), 0..(elem(:binary.match(List.first(row), "("), 0) - 1))

        upload_to_database(
          rows,
          Enum.drop(avengers, 1),
          # Storing the group in function parameter to assign students to it later
          elem(Course.create_group(group_name, avenger, mentor), 1)
        )

      # Have to skip this row as it is just a header
      List.first(row) == "Name" ->
        upload_to_database(rows, avengers, current_group)

      # Adding students to their respective groups
      true ->
        [student_name | [student_nusnet | _]] = row
        {:ok, student} = Accounts.get_or_create_user(student_name, :student, student_nusnet)

        Course.add_student_to_group(
          current_group,
          student
        )

        upload_to_database(rows, avengers, current_group)
    end
  end
end
