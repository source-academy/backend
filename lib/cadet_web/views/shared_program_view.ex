defmodule CadetWeb.SharedProgramView do
  use CadetWeb, :view

  def render("index.json", %{shared_programs: shared_programs}) do
    %{
      data: Enum.map(shared_programs, &render_shared_program/1)
    }
  end

  def render("show.json", %{uuid: uuid}) do
    %{uuid: uuid}
  end

  defp render_shared_program(shared_program) do
    %{
      uuid: shared_program.uuid,
      json: shared_program.data
      # Add other attributes as needed
    }
  end
end
