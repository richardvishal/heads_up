defmodule HeadsUpWeb.Api.IncidentsController do
  use HeadsUpWeb, :controller
  alias HeadsUp.Admin

  def index(conn, _params) do
    render(conn, %{incidents: Admin.list_incidents()})
  end

  def show(conn, %{"id" => id}) do
    render(conn, %{incident: Admin.get_incident!(id)})
  rescue
    Ecto.NoResultsError ->
      conn
      |> put_status(:not_found)
      |> put_view(json: HeadsUpWeb.ErrorJSON)
      |> render(:"404")
  end

  def create(conn, %{"incident" => incident_params}) do
    case Admin.create_incident(incident_params) do
      {:ok, incident} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", ~p"/api/incidents/#{incident}")
        |> render(:show, incident: incident)

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(json: HeadsUpWeb.ChangesetJSON)
        |> render(:error, changeset: changeset)
    end
  end
end
