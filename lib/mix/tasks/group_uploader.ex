defmodule Mix.Tasks.GroupUploader do
  use Mix.Task

  alias Cadet.{Accounts, Course}

  @moduledoc """
  Mix Task to upload the tutorial groups and it's
  participants
  """

  def run([groups_arg | [avengers_arg | _]]) do
    Mix.Task.run("app.start")
    # Removing unneccesary headers
    groups =
      groups_arg
      |> Xlsxir.multi_extract()
      |> Keyword.get(:ok)
      |> Xlsxir.get_list()
      |> Enum.drop(3)

    avengers =
      avengers_arg
      |> Xlsxir.multi_extract()
      |> Keyword.get(:ok)
      |> Xlsxir.get_list()
      |> Enum.drop(1)

    helper(groups, avengers, nil)
  end

  defp helper(rows, avengers, current_group) do
    [row | rows] = rows
    
    cond do
      row == nil || List.first(row) == "//" ->
        "End"

      String.contains?(List.first(row), "Total Students") ->
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

        group_name =
          String.slice(List.first(row), 0..(elem(:binary.match(List.first(row), "("), 0) - 1))

        helper(
          rows,
          Enum.drop(avengers, 1),
          elem(Course.create_group(group_name, avenger, mentor), 1)
        )

      List.first(row) == "Name" ->
        helper(rows, avengers, current_group)

      true ->
        [student_name | [student_nusnet | _]] = row
        {:ok, student} = Accounts.get_or_create_user(student_name, :student, student_nusnet)

        Course.add_student_to_group(
          current_group,
          student
        )

        helper(rows, avengers, current_group)
    end
  end
end
