defmodule HeadsUpWeb.Incidents.Index do
  use HeadsUpWeb, :live_view
  alias HeadsUp.Incidents

  def mount(_params, _session, socket) do
    socket = stream(socket, :incidents, Incidents.list_incidents())
    # IO.inspect(socket.assigns.streams, label: "MOUNT")
    socket = assign(socket, :page_title, "Incidents") |> assign(:form, to_form(%{}))

    # socket =
    #   attach_hook(socket, :log_stream, :after_render, fn
    #     socket ->
    #       # inspect the stream
    #       IO.inspect(socket.assigns.streams, label: "AFTER MOUNT")

    #       socket
    #   end)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="incident-index">
      <.headline :if={false}>
        <.icon name="hero-trophy-mini" /> 25 Incidents Resolved This Month!
        <:tagline :let={vibe}>
          Thanks for pitching in. {vibe}
        </:tagline>
      </.headline>

      <.filter_form form={@form} />

      <div class="incidents" id="incidents" phx-update="stream">
        <.incident_card
          :for={{dom_id, incident} <- @streams.incidents}
          incident={incident}
          id={dom_id}
        />
      </div>
    </div>
    """
  end

  attr :incident, HeadsUp.Incidents.Incident, required: true
  attr :id, :string, required: true

  def incident_card(assigns) do
    ~H"""
    <.link navigate={~p"/incidents/#{@incident}"} id={@id}>
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
    </.link>
    """
  end

  def filter_form(assigns) do
    ~H"""
    <.form for={@form} id="filter-form" phx-change="filter">
      <.input field={@form[:q]} placeholder="Search...." autocomplete="off" />
      <.input
        type="select"
        field={@form[:status]}
        options={[:pending, :resolved, :canceled]}
        prompt="Status"
      />
      <.input type="select" field={@form[:sort_by]} options={[:status, :priority]} prompt="Sort By" />
    </.form>
    """
  end

  def handle_event("filter", params, socket) do
    socket =
      assign(socket, :form, to_form(params))
      |> stream(:incidents, Incidents.filter_incidents(params), reset: true)

    {:noreply, socket}
  end
end
