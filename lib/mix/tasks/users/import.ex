defmodule Mix.Tasks.Cadet.Users.Import do
  @moduledoc """
  Import user and grouping information from several csv files.

  To use this, you need to prepare 3 csv files:
  1. List of all the students together with their group names
  2. List of all the leaders together with their group names
  3. List of all the mentors together with their group names

  For all the files, they must be comma-separated csv and in this format:

  ```
  name,username,group_name
  ```

  (Username could be e.g. NUSNET ID)

  Note that group names must be unique.
  """

  @shortdoc "Import user and grouping information from csv files."

  use Mix.Task

  require Logger

  alias Cadet.{Accounts, Courses, Repo}
  alias Cadet.Courses.Group
  alias Cadet.Accounts.User

  def run(_args) do
    # Required for Ecto to work properly, from Mix.Ecto
    if function_exported?(Mix.Task, :run, 2), do: Mix.Task.run("app.start")

    students_csv_path = trimmed_gets("Path to students csv (leave blank to skip): ")
    leaders_csv_path = trimmed_gets("Path to leaders csv (leave blank to skip): ")
    mentors_csv_path = trimmed_gets("Path to mentors csv (leave blank to skip): ")

    Repo.transaction(fn ->
      students_csv_path != "" && process_students_csv(students_csv_path)
      leaders_csv_path != "" && process_leaders_csv(leaders_csv_path)
      mentors_csv_path != "" && process_mentors_csv(mentors_csv_path)
    end)
  end

  defp process_students_csv(path) when is_binary(path) do
    if File.exists?(path) do
      csv_stream = path |> File.stream!() |> CSV.decode(strip_fields: true)

      for {:ok, [name, username, group_name]} <- csv_stream do
        with {:ok, group = %Group{}} <- Courses.get_or_create_group(group_name),
             {:ok, %User{}} <-
               Accounts.insert_or_update_user(%{
                 username: username,
                 name: name,
                 role: :student,
                 group: group
               }) do
          :ok
        else
          error ->
            Logger.error(
              "Unable to insert student (name: #{name}, username: #{username}, " <>
                "group_name: #{group_name})"
            )

            Logger.error("error: #{inspect(error, pretty: true)}")

            Repo.rollback(error)
        end
      end

      Logger.info("Imported students csv at #{path}")
    else
      Logger.error("Cannot find students csv at #{path}")
    end
  end

  defp process_leaders_csv(path) when is_binary(path) do
    if File.exists?(path) do
      csv_stream = path |> File.stream!() |> CSV.decode(strip_fields: true)

      for {:ok, [name, username, group_name]} <- csv_stream do
        with {:ok, leader = %User{}} <-
               Accounts.insert_or_update_user(%{username: username, name: name, role: :staff}),
             {:ok, %Group{}} <-
               Course.insert_or_update_group(%{name: group_name, leader: leader}) do
          :ok
        else
          error ->
            Logger.error(
              "Unable to insert leader (name: #{name}, username: #{username}, " <>
                "group_name: #{group_name})"
            )

            Logger.error("error: #{inspect(error, pretty: true)}")

            Repo.rollback(error)
        end
      end

      Logger.info("Imported leaders csv at #{path}")
    else
      Logger.error("Cannot find leaders csv at #{path}")
    end
  end

  defp process_mentors_csv(path) when is_binary(path) do
    if File.exists?(path) do
      csv_stream = path |> File.stream!() |> CSV.decode(strip_fields: true)

      for {:ok, [name, username, group_name]} <- csv_stream do
        with {:ok, mentor = %User{}} <-
               Accounts.insert_or_update_user(%{username: username, name: name, role: :staff}),
             {:ok, %Group{}} <-
               Course.insert_or_update_group(%{name: group_name, mentor: mentor}) do
          :ok
        else
          error ->
            Logger.error(
              "Unable to insert mentor (name: #{name}, username: #{username}, " <>
                "group_name: #{group_name})"
            )

            Logger.error("error: #{inspect(error, pretty: true)}")

            Repo.rollback(error)
        end
      end

      Logger.info("Imported mentors csv at #{path}")
    else
      Logger.error("Cannot find mentors csv at #{path}")
    end
  end

  @spec trimmed_gets(String.t()) :: String.t()
  defp trimmed_gets(prompt) when is_binary(prompt) do
    prompt
    |> IO.gets()
    |> String.trim()
  end
end
