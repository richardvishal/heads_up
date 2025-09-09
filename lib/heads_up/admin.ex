defmodule HeadsUp.Admin do
  alias HeadsUp.Incidents.Incident
  alias HeadsUp.Incidents

  alias HeadsUp.Repo
  import Ecto.Query

  def list_incidents do
    Incident
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  def create_incident(attrs \\ %{}) do
    %Incident{}
    |> Incident.changeset(attrs)
    |> Repo.insert()
  end

  def change_incident(%Incident{} = incident, attrs \\ %{}) do
    incident |> Incident.changeset(attrs)
  end

  def get_incident!(id), do: Repo.get!(Incident, id)

  def update_incident(%Incident{} = incident, attrs) do
    incident
    |> Incident.changeset(attrs)
    |> Repo.update()
    |> case do
      {:error, _} = error ->
        error

      {:ok, incident} ->
        incident = Repo.preload(incident, [:category, heroic_response: :user])
        Incidents.broadcast(incident.id, {:incident_updated, incident})
        {:ok, incident}
    end
  end

  def delete_incident(%Incident{} = incident) do
    Repo.delete(incident)
  end

  def draw_heroic_response(%Incident{status: :resolved} = incident) do
    incident = Repo.preload(incident, :responses)

    case incident.responses do
      [] ->
        {:error, "No responses to draw!"}

      responses ->
        response = Enum.random(responses)

        {:ok, _incident} =
          update_incident(incident, %{
            heroic_response_id: response.id
          })
    end
  end

  def draw_heroic_response(%Incident{}) do
    {:error, "Incident must be resolved to draw a heroic response!"}
  end
end
