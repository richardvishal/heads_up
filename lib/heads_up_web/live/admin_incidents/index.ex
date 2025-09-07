defmodule HeadsUpWeb.AdminIncidents.Index do
  use HeadsUpWeb, :live_view
  alias HeadsUp.Admin
  import HeadsUpWeb.CustomComponents
  on_mount {HeadsUpWeb.UserAuth, :ensure_authenticated}

  def mount(_params, _session, socket) do
    socket =
      assign(socket, :page_title, "Listing Incidents")
      |> stream(:incidents, Admin.list_incidents())

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="admin-index">
      <.button phx-click={JS.toggle(to: "#joke", in: "fade-in", out: "fade-out")}>
        Toggle Joke
      </.button>
      <div id="joke" class="joke hidden" phx-click={toggle_blur()}>
        Why shouldn't you trust trees, {@current_user.username}?
      </div>
      <.header>
        {@page_title}
        <:actions>
          <.link class="button" navigate={~p"/admin/incidents/new"}>New Incident</.link>
        </:actions>
      </.header>
      <.table
        id="incidents"
        rows={@streams.incidents}
        row_click={fn {_dom_id, incident} -> JS.navigate(~p"/incidents/#{incident}") end}
      >
        <:col :let={{_dom_id, incident}} label="Name">
          <.link navigate={~p"/incidents/#{incident}"}>
            {incident.name}
          </.link>
        </:col>
        <:col :let={{_dom_id, incident}} label="Status">
          <.badge status={incident.status} />
        </:col>
        <:action :let={{_dom_id, incident}}>
          <.link navigate={~p"/admin/incidents/#{incident}/edit"}>Edit</.link>
        </:action>

        <:action :let={{dom_id, incident}}>
          <.link phx-click={delete_and_fade_out(dom_id, incident)} data-confirm="Are you sure?">
            <.icon name="hero-trash" class="h-4 w-4" /> Delete
          </.link>
        </:action>
      </.table>
    </div>
    """
  end

  def handle_event("delete", %{"id" => id}, socket) do
    incident = Admin.get_incident!(id)
    {:ok, _} = Admin.delete_incident(incident)

    {:noreply, stream_delete(socket, :incidents, incident)}
  end

  defp toggle_blur() do
    JS.toggle_class("blur", to: "#joke")
    |> JS.add_class("animate-bounce", to: "#joke")
    |> JS.remove_class("animate-bounce", to: "#joke", time: 1000)
  end

  defp delete_and_fade_out(dom_id, incident) do
    JS.push("delete", value: %{id: incident.id})
    |> JS.add_class(
      "fade-out",
      to: "##{dom_id}"
    )
  end
end
