defmodule HeadsUpWeb.AdminIncidents.Form do
  use HeadsUpWeb, :live_view

  alias HeadsUp.Admin

  def mount(_params, _session, socket) do
    socket =
      assign(socket, :page_title, "New Incident") |> assign(:form, to_form(%{}, as: "incident"))

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <.header>
      {@page_title}
    </.header>
    <.simple_form id="incident-form" for={@form} phx-submit="save">
      <.input field={@form[:name]} label="Name" />
      <.input field={@form[:priority]} label="Priority" />
      <.input
        prompt="Select Status"
        type="select"
        options={[:pending, :resolved, :canceled]}
        field={@form[:status]}
        label="Status"
      />
      <.input type="textarea" field={@form[:description]} label="Description" />
      <.input field={@form[:image_path]} label="Image Path" />
      <:actions>
        <.button phx-disable-with="Saving...">Save</.button>
      </:actions>
    </.simple_form>
    <.back navigate={~p"/admin/incidents"}>Back</.back>
    """
  end

  def handle_event("save", %{"incident" => incident_params}, socket) do
    Admin.create_incident(incident_params)
    socket = push_navigate(socket, to: ~p"/admin/incidents")

    {:noreply, socket}
  end
end
