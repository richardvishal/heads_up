defmodule HeadsUpWeb.AdminIncidents.Form do
  use HeadsUpWeb, :live_view

  alias HeadsUp.Admin
  alias HeadsUp.Incidents.Incident

  def mount(params, _session, socket) do
    {:ok, apply_action(socket.assigns.live_action, params, socket)}
  end

  defp apply_action(:new, _params, socket) do
    incident = %Incident{}
    changeset = Admin.change_incident(incident)

    socket
    |> assign(:page_title, "New Incident")
    |> assign(:form, to_form(changeset))
    |> assign(:incident, incident)
  end

  defp apply_action(:edit, %{"id" => id}, socket) do
    incident = Admin.get_incident!(id)
    changeset = Admin.change_incident(incident)

    socket
    |> assign(:page_title, "Edit Incident")
    |> assign(:form, to_form(changeset))
    |> assign(:incident, incident)
  end

  def render(assigns) do
    ~H"""
    <.header>
      {@page_title}
    </.header>
    <.simple_form id="incident-form" for={@form} phx-submit="save" phx-change="validate">
      <.input field={@form[:name]} label="Name" />
      <.input field={@form[:priority]} label="Priority" />
      <.input
        prompt="Select Status"
        type="select"
        options={[:pending, :resolved, :canceled]}
        field={@form[:status]}
        label="Status"
      />
      <.input type="textarea" field={@form[:description]} label="Description" phx-debounce="blur" />
      <.input field={@form[:image_path]} label="Image Path" />
      <:actions>
        <.button phx-disable-with="Saving...">Save</.button>
      </:actions>
    </.simple_form>
    <.back navigate={~p"/admin/incidents"}>Back</.back>
    """
  end

  def handle_event("validate", %{"incident" => incident_params}, socket) do
    changeset = Admin.change_incident(socket.assigns.incident, incident_params)

    socket =
      socket |> assign(:form, to_form(changeset, action: :validate))

    {:noreply, socket}
  end

  def handle_event("save", %{"incident" => incident_params}, socket) do
    case Admin.create_incident(incident_params) do
      {:ok, _incident} ->
        {:noreply,
         socket
         |> put_flash(:info, "Incident created successfully")
         |> push_navigate(to: ~p"/admin/incidents")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
