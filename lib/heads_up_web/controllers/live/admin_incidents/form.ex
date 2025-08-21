defmodule HeadsUpWeb.AdminIncidents.Form do
  use HeadsUpWeb, :live_view

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
    <.simple_form id="incident-form" for={@form}>
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

      <.button>Save</.button>
      <:actions>
      <.back navigate={~p"/admin/incidents"}>Back</.back>
      </:actions>
    </.simple_form>
    """
  end
end
