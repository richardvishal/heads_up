defmodule HeadsUp.Incidents do
  alias HeadsUp.Incidents.Incident
  alias HeadsUp.Repo

  @behaviour HeadsUp.IncidentsBehaviour

  import Ecto.Query

  def subscribe(incident_id) do
    Phoenix.PubSub.subscribe(HeadsUp.PubSub, "incidents:#{incident_id}")
  end

  def broadcast(incident_id, message) do
    Phoenix.PubSub.broadcast(HeadsUp.PubSub, "incidents:#{incident_id}", message)
  end

  def list_incidents do
    Repo.all(Incident)
  end

  def filter_incidents(filter) do
    Incident
    |> with_status(filter["status"])
    |> search_by(filter["q"])
    |> with_category(filter["category"])
    |> sort_by(filter["sort_by"])
    |> preload(:category)
    |> Repo.all()
  end

  defp with_category(query, slug) when slug in ["", nil], do: query

  defp with_category(query, slug) do
    from(i in query, join: c in assoc(i, :category), where: c.slug == ^slug)
  end

  defp with_status(query, status) when status in ~w(pending resolved canceled) do
    where(query, status: ^status)
  end

  defp with_status(query, _), do: query

  defp search_by(query, q) when q in ["", nil], do: query

  defp search_by(query, q) do
    where(query, [i], ilike(i.name, ^"%#{q}%"))
  end

  defp sort_by(query, "name"), do: order_by(query, desc: :name)
  defp sort_by(query, "priority_desc"), do: order_by(query, desc: :priority)
  defp sort_by(query, "priority_asc"), do: order_by(query, asc: :priority)

  defp sort_by(query, "category") do
    query
    |> join(:inner, [i], c in assoc(i, :category))
    |> order_by([_i, c], asc: c.name)
  end

  defp sort_by(query, _), do: query

  def get_incident!(id),
    do: Repo.get!(Incident, id) |> Repo.preload([:category, heroic_response: :user])

  @impl HeadsUp.IncidentsBehaviour
  def urgent_incidents(incident) do
    incidents =
      from(i in Incident, where: i.id != ^incident.id and i.priority == 3)
      |> Repo.all()

    {:ok, %{urgent_incidents: incidents}}
  end

  def list_responses(incident) do
    incident
    |> Ecto.assoc(:responses)
    |> order_by(desc: :inserted_at)
    |> preload(:user)
    |> Repo.all()
  end
end
