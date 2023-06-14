defmodule CadetWeb.ControllerHelper do
  @moduledoc """
  Contains helper functions for controllers.
  """

  alias Plug.Conn

  alias PhoenixSwagger.Schema

  @doc """
  Sends a response based on a standard result.
  """
  @spec handle_standard_result(
          :ok
          | {:error, {atom(), String.t()}}
          | {:ok, any},
          Plug.Conn.t(),
          String.t() | nil
        ) :: Plug.Conn.t()
  def handle_standard_result(result, conn, success_response \\ nil)

  def handle_standard_result({:ok, _}, conn, success_response),
    do: handle_standard_result(:ok, conn, success_response)

  def handle_standard_result(:ok, conn, nil), do: Conn.send_resp(conn, :no_content, "")

  def handle_standard_result(:ok, conn, ""), do: Conn.send_resp(conn, :no_content, "")

  def handle_standard_result(:ok, conn, success_response),
    do: Conn.send_resp(conn, :ok, success_response)

  def handle_standard_result({:error, {code, response}}, conn, _),
    do: Conn.send_resp(conn, code, response)

  def schema_array(type, extra \\ []) do
    %Schema{
      type: :array,
      items:
        %Schema{
          type: type
        }
        |> Map.merge(Enum.into(extra, %{}))
    }
  end

  def changeset_error_to_string(changeset) do
    errors =
      Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
        Enum.reduce(opts, msg, fn {key, value}, acc ->
          String.replace(acc, "%{#{key}}", to_string(value))
        end)
      end)

    errors
    |> Enum.reduce("", fn {k, v}, acc ->
      joined_errors = Enum.join(v, "; ")
      "#{acc}#{k}: #{joined_errors}\n"
    end)
  end
end
