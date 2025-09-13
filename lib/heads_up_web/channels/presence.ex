defmodule HeadsUpWeb.Presence do
  @moduledoc """
  Provides presence tracking to channels and processes.

  See the [`Phoenix.Presence`](https://hexdocs.pm/phoenix/Phoenix.Presence.html)
  docs for more details.
  """
  use Phoenix.Presence,
    otp_app: :heads_up,
    pubsub_server: HeadsUp.PubSub

  def track_user(id, current_user) do
    {:ok, _} =
      track(self(), topic(id), current_user.username, %{
        online_at: System.system_time(:second)
      })
  end

  def subscribe(id), do: Phoenix.PubSub.subscribe(HeadsUp.PubSub, "updates:" <> topic(id))

  def list_presences(id) do
    list(topic(id))
    |> Enum.map(fn {username, %{metas: metas}} ->
      %{
        id: username,
        metas: metas
      }
    end)
  end

  defp topic(incident_id), do: "incident_onlookers:#{incident_id}"

  def init(_opts) do
    {:ok, %{}}
  end

  def handle_metas(topic, %{joins: joins, leaves: leaves}, presences, state) do
    for {username, _} <- joins do
      Phoenix.PubSub.broadcast(
        HeadsUp.PubSub,
        "updates:" <> topic,
        {:user_joined,
         %{
           id: username,
           metas: Map.fetch!(presences, username)
         }}
      )
    end

    for {username, _} <- leaves do
      metas =
        case Map.fetch(presences, username) do
          {:ok, presence_metas} -> presence_metas
          :error -> []
        end

      Phoenix.PubSub.broadcast(
        HeadsUp.PubSub,
        "updates:" <> topic,
        {:user_left,
         %{
           id: username,
           metas: metas
         }}
      )
    end

    {:ok, state}
  end
end
