defmodule CadetWeb.SharedProgramJSON do
  alias Cadet.SharedPrograms.SharedProgram

  @doc """
  Renders a list of shared_programs.
  """
  def index(%{shared_programs: shared_programs}) do
    %{data: for(shared_program <- shared_programs, do: data(shared_program))}
  end

  @doc """
  Renders a single shared_program.
  """
  def show(%{shared_program: shared_program}) do
    %{data: data(shared_program)}
  end

  defp data(%SharedProgram{} = shared_program) do
    %{
      id: shared_program.id,
      uuid: shared_program.uuid,
      data: shared_program.data
    }
  end
end
