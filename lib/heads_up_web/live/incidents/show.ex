defmodule HeadsUpWeb.Incidents.Show do
  alias HeadsUpWeb.Presence
  use HeadsUpWeb, :live_view
  alias HeadsUp.Incidents
  alias HeadsUp.Responses
  alias HeadsUp.Responses.Response

  on_mount {HeadsUpWeb.UserAuth, :mount_current_user}

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :form, to_form(Responses.change_response(%Response{})))}
  end

  def handle_params(%{"id" => id}, _uri, socket) do
    %{current_user: current_user} = socket.assigns

    if connected?(socket) do
      Incidents.subscribe(id)

      if current_user do
        Presence.track_user(id, current_user)
        Presence.subscribe(id)
      end
    end

    presences = Presence.list_presences(id)

    incident = Incidents.get_incident!(id)
    responses = Incidents.list_responses(incident)

    socket =
      socket
      |> assign(
        incident: incident,
        page_title: incident.name
      )
      |> stream(:responses, responses)
      |> stream(:presences, presences)
      |> assign(:responses_count, length(responses))
      |> assign_async(:urgent_incidents, fn ->
        {:ok, %{urgent_incidents: Incidents.urgent_incidents(incident)}}
        # {:error, "error"}
      end)

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="incident-show">
      <.headline :if={@incident.heroic_response}>
        <.icon name="hero-sparkles-solid" />
        Heroic Responder: {@incident.heroic_response.user.username}
        <:tagline>
          {@incident.heroic_response.note}
        </:tagline>
      </.headline>
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
          <div class="totals">
            {@responses_count} Responses
          </div>
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
          <div id="responses" phx-update="stream">
            <.response
              :for={{dom_id, response} <- @streams.responses}
              id={dom_id}
              response={response}
            />
          </div>
        </div>
        <div class="right">
          <.urgent_incidents incidents={@urgent_incidents} />
          <.onlookers presences={@streams.presences} />
        </div>
      </div>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :response, Response, required: true

  defp response(assigns) do
    ~H"""
    <div class="response" id={@id}>
      <span class="timeline"></span>
      <section>
        <div class="avatar">
          <.icon name="hero-user-solid" />
        </div>
        <div>
          <span class="username">
            {@response.user.username}
          </span>
          <span>
            {@response.status}
          </span>
          <blockquote>
            {@response.note}
          </blockquote>
        </div>
      </section>
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

  def onlookers(assigns) do
    ~H"""
    <section>
      <h4>Onlookers</h4>
      <ul class="presences" id="onlookers" phx-update="stream">
        <li :for={{dom_id, %{id: username, metas: metas}} <- @presences} id={dom_id}>
          <.icon name="hero-user-circle-solid" class="w-5 h-5" /> {username} ({length(metas)})
        </li>
      </ul>
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
        socket =
          socket
          |> assign(form: to_form(Responses.change_response(%Response{})))

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def handle_info({:new_response, response}, socket) do
    socket =
      socket
      |> stream_insert(:responses, response, at: 0)
      |> update(:responses_count, &(&1 + 1))

    {:noreply, socket}
  end

  def handle_info({:incident_updated, incident}, socket) do
    {:noreply, assign(socket, :incident, incident)}
  end

  def handle_info({:user_joined, presence}, socket) do
    {:noreply, stream_insert(socket, :presences, presence)}
  end

  def handle_info({:user_left, presence}, socket) do
    case presence.metas == [] do
      false ->
        {:noreply, stream_insert(socket, :presences, presence)}

      true ->
        {:noreply, stream_delete(socket, :presences, presence)}
    end
  end
end
