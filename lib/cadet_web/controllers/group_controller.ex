defmodule CadetWeb.GroupController do
  use CadetWeb, :controller

  use PhoenixSwagger

  alias Cadet.Course.Groups

  def index(conn, _) do
    user = conn.assigns.current_user
    result = Groups.get_group_overviews(user)

    case result do
      {:ok, groups} ->
        render(conn, "index.json", groups: groups)

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)
    end
  end

  swagger_path :index do
    get("/groups")

    summary("Get a list of all the groups")

    security([%{JWT: []}])

    produces("application/json")

    response(200, "OK", Schema.ref(:GroupsList))
    response(401, "Unauthorised")
  end

  def swagger_definitions do
    %{
      GroupsList:
        swagger_schema do
          description("A list of all groups")
          type(:array)
          items(Schema.ref(:GroupOverview))
        end,
      GroupOverview:
        swagger_schema do
          properties do
            id(:integer, "The group id", required: true)
            avengerName(:string, "The name of the group's avenger", required: true)
            groupName(:string, "The name of the group", required: true)
          end
        end
    }
  end
end
