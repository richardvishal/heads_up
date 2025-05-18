defmodule HeadsUpWeb.Incidents.Index do
  alias HeadsUp.Incidents
  use HeadsUpWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, :incidents, Incidents.list_incidents())
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="incident-index">
      <div class="incidents">
        <.incident_card :for={incident <- @incidents} incident={incident} />
      </div>
    </div>
    """
  end

  attr :incident, HeadsUp.Incident, required: true

  def incident_card(assigns) do
    ~H"""
    <div class="card">
      <img src={@incident.image_path} />
      <h2>{@incident.name}</h2>
      <div class="details">
        <.badge status={@incident.status} />
        <div class="priority">
          {@incident.priority}
        </div>
      </div>
    </div>
    """
  end

  attr :status, :atom, required: true, values: [:pending, :resolved]

  def badge(assigns) do
    ~H"""
    <div class="rounded-md px-2 py-1 text-xs font-medium uppercase inline-block border text-lime-600
    border-lime-600">
      {@status}
    </div>
    """
  end
end
