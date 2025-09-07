defmodule HeadsUpWeb.Incidents.Show do
  use HeadsUpWeb, :live_view
  alias HeadsUp.Incidents
  alias HeadsUp.Responses
  alias HeadsUp.Responses.Response

  on_mount {HeadsUpWeb.UserAuth, :mount_current_user}

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :form, to_form(Responses.change_response(%Response{})))}
  end

  def handle_params(%{"id" => id}, _uri, socket) do
    incident = Incidents.get_incident!(id)

    socket =
      socket
      |> assign(
        incident: incident,
        page_title: incident.name
      )
      |> assign_async(:urgent_incidents, fn ->
        {:ok, %{urgent_incidents: Incidents.urgent_incidents(incident)}}
        # {:error, "error"}
      end)

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="incident-show">
      <div class="incident">
        <img src={@incident.image_path} />
        <section>
          <.badge status={@incident.status} />
          <header>
            <div>
              <h2>
                {@incident.name}
              </h2>
              <h3>
                {@incident.category.name}
              </h3>
            </div>
            <div class="priority">
              {@incident.priority}
            </div>
          </header>
          <div class="description">
            {@incident.description}
          </div>
        </section>
      </div>
      <div class="activity">
        <div class="left">
          <div :if={@incident.status == :pending}>
            <%= if @current_user do %>
              <.response_form form={@form} />
            <% else %>
              <.link navigate={~p"/users/log-in"} class="button">
                Log In To Post
              </.link>
            <% end %>
          </div>
        </div>
        <div class="right">
          <.urgent_incidents incidents={@urgent_incidents} />
        </div>
      </div>
    </div>
    """
  end


  defp response_form(assigns) do
    ~H"""
    <.form for={@form} id="response-form" phx-change="validate" phx-submit="save">
      <.input
        type="select"
        options={[:enroute, :arrived, :departed]}
        field={@form[:status]}
        prompt="Choose a status"
      />
      <.input field={@form[:note]} placeholder="Notes.." type="textarea" autofocus />
      <.button>Post</.button>
    </.form>
    """
  end

  def urgent_incidents(assigns) do
    ~H"""
    <section>
      <h4>
        Urgent Incidents
      </h4>
      <.async_result :let={result} assign={@incidents}>
        <:loading>
          <div class="loading">
            <div class="spinner"></div>
          </div>
        </:loading>
        <:failed :let={{:error, reason}}>
          <div class="failed">
            Uhh oh! {reason}
          </div>
        </:failed>
        <ul class="incidents">
          <li :for={incident <- result}>
            <.link navigate={~p"/incidents/#{incident}"}>
              <img src={incident.image_path} />
              {incident.name}
            </.link>
          </li>
        </ul>
      </.async_result>
    </section>
    """
  end

  def handle_event("validate", %{"response" => response_params}, socket) do
    socket =
      assign(
        socket,
        :form,
        to_form(Responses.change_response(%Response{}, response_params), action: :validate)
      )

    {:noreply, socket}
  end

  def handle_event("save", %{"response" => response_params}, socket) do
    %{incident: incident, current_user: user} = socket.assigns

    case Responses.create_response(incident, user, response_params) do
      {:ok, _response} ->
        socket = assign(socket, form: to_form(Responses.change_response(%Response{})))
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
