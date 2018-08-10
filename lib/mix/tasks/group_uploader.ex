defmodule Mix.Tasks.GroupUploader do
  use Mix.Task

  alias Cadet.Course
  alias Cadet.Accounts

  @shortdoc "Parses excel file and creates student groups"

  def run(args) do
    Mix.Task.run("app.start")
    # Removing unneccesary headers 
    groups =
      Xlsxir.get_list(Xlsxir.multi_extract(Enum.at(args, 0))[:ok])
      |> Enum.drop(3)

    avengers =
      Xlsxir.get_list(Xlsxir.multi_extract(Enum.at(args, 1))[:ok])
      |> Enum.drop(1)

    helper(groups, 0, avengers, 0, nil)
  end

  defp helper(rows, row_index, avengers, avenger_index, current_group) do
    row = Enum.at(rows, row_index)
    current_avenger = Enum.at(avengers, avenger_index)

    cond do
      row == nil || List.first(row) == "//" ->
        "End"

      String.contains?(List.first(row), "Total Students") ->
        avenger =
          Accounts.get_or_create_user(
            List.first(current_avenger),
            :staff,
            Enum.at(current_avenger, 1)
          )

        mentor =
          Accounts.get_or_create_user(
            Enum.at(current_avenger, 3),
            :staff,
            Enum.at(current_avenger, 4)
          )

        group_name =
          String.slice(List.first(row), 0..(elem(:binary.match(List.first(row), "("), 0) - 1))

        helper(
          rows,
          row_index + 1,
          avengers,
          avenger_index + 1,
          elem(Course.create_group(group_name, avenger, mentor), 1)
        )

      List.first(row) == "Name" ->
        helper(rows, row_index + 1, avengers, avenger_index, current_group)

      true ->
        student_name = List.first(row)
        student_nusnet = Enum.at(row, 1)

        Course.add_student_to_group(
          current_group,
          Accounts.get_or_create_user(student_name, :student, student_nusnet)
        )

        helper(rows, row_index + 1, avengers, avenger_index, current_group)
    end
  end
end
