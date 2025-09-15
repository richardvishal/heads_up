defmodule HeadsUpWeb.EffortLive do
  use HeadsUpWeb, :live_view

  def mount(_params, _session, socket) do
    if connected?(socket), do: Process.send_after(self(), :update_responders, 2000)
    socket = assign(socket, responders: 0, minutes_per_responder: 10, page_title: "Effort")
    # IO.inspect(socket)
    # IO.inspect(self(), label: "MOUNT")
    {:ok, socket}
  end

  def render(assigns) do
    # IO.inspect(self(), label: "RENDER")

    ~H"""
    <div class="effort">
      <h1>Community Love</h1>
      <section>
        <button phx-click="add" phx-value-responders="3">
          +3
        </button>
        <div>
          {@responders}
        </div>
        &times;
        <div>
          {@minutes_per_responder}
        </div>
        =
        <div>
          {@responders * @minutes_per_responder}
        </div>
      </section>
      <form phx-submit="recalculate">
        <label> Minutes per Responder:</label>
        <input type="number" name="minutes_per_responder" value={@minutes_per_responder} />
      </form>
    </div>
    """
  end

  def handle_event("add", %{"responders" => responders} = _unsigned_params, socket) do
    socket = update(socket, :responders, &(&1 + String.to_integer(responders)))
    # IO.inspect(socket)
    # IO.inspect(self(), label: "EVENT")
    # raise "💥"
    {:noreply, socket}
  end

  def handle_event("recalculate", %{"minutes_per_responder" => minutes_per_responder}, socket) do
    socket = assign(socket, :minutes_per_responder, String.to_integer(minutes_per_responder))
    {:noreply, socket}
  end

  def handle_info(:update_responders, socket) do
    Process.send_after(self(), :update_responders, 2000)
    {:noreply, update(socket, :responders, &(&1 + 3))}
  end
end
