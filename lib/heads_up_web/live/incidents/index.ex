defmodule HeadsUpWeb.Incidents.Index do
  use HeadsUpWeb, :live_view
  alias HeadsUp.Incidents

  def mount(_params, _session, socket) do
    # IO.inspect(socket.assigns.streams, label: "MOUNT")
    socket = assign(socket, :page_title, "Incidents")

    # socket =
    #   attach_hook(socket, :log_stream, :after_render, fn
    #     socket ->
    #       # inspect the stream
    #       IO.inspect(socket.assigns.streams, label: "AFTER MOUNT")

    #       socket
    #   end)

    {:ok, socket}
  end

  def handle_params(params, _uri, socket) do
    socket =
      assign(socket, :form, to_form(params))
      |> stream(:incidents, Incidents.filter_incidents(params), reset: true)

    {:noreply, socket}
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
        <div id="empty" class="no-results only:block hidden">
          No incidents found. Try adjusting your filters.
        </div>
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
      <div class="category">
      {@incident.category.name}
      </div>
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
    <.form for={@form} id="filter-form" phx-change="filter" phx-submit="filter">
      <.input field={@form[:q]} placeholder="Search...." autocomplete="off" phx-debounce="1000" />
      <.input
        type="select"
        field={@form[:status]}
        options={[:pending, :resolved, :canceled]}
        prompt="Status"
      />
      <.input
        type="select"
        field={@form[:sort_by]}
        options={[
          Name: "name",
          "Priority High to Low": "priority_desc",
          "Priority Low to High": "priority_asc"
        ]}
        prompt="Sort By"
      />
      <.link patch={~p"/incidents"}>
        Reset
      </.link>
    </.form>
    """
  end

  def handle_event("filter", params, socket) do
    params = Map.take(params, ["q", "status", "sort_by"]) |> Map.reject(fn {_, v} -> v == "" end)
    socket = push_patch(socket, to: ~p"/incidents?#{params}")

    {:noreply, socket}
  end
end
