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
end
