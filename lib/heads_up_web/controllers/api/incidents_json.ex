defmodule HeadsUpWeb.Api.IncidentsJSON do
  def index(%{incidents: incidents}) do
    %{incidents: for(incident <- incidents, do: data(incident))}
  end

  def show(%{incident: incident}) do
    %{incident: data(incident)}
  end

  defp data(incident) do
    %{id: incident.id, name: incident.name, status: incident.status}
  end
end
