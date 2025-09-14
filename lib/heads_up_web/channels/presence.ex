defmodule HeadsUpWeb.Presence do
  @moduledoc """
  Provides presence tracking to channels and processes.
  """

  use Phoenix.Presence,
    otp_app: :heads_up,
    pubsub_server: HeadsUp.PubSub

  # Use runtime lookup to avoid compile-time resolution of test mocks.
  defp presence_module, do: Application.get_env(:heads_up, :presence_module, Phoenix.Presence)
  defp pubsub_module, do: Application.get_env(:heads_up, :pubsub_module, Phoenix.PubSub)

  @doc """
  Track a user on the presence topic. Returns `{:ok, _}` or `{:error, reason}`.
  """
  def track_user(id, current_user) do
    case presence_module().track(self(), topic(id), current_user.username, %{
           online_at: System.system_time(:second)
         }) do
      {:ok, result} -> {:ok, result}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc "Subscribe to presence updates for an incident"
  def subscribe(id) do
    pubsub_module().subscribe(HeadsUp.PubSub, "updates:" <> topic(id))
  end

  @doc "Return presences as a list of %{id: username, metas: metas_list} or metas nil when absent"
  def list_presences(id) do
    presence_module()
    |> then(& &1.list(topic(id)))
    |> Enum.map(fn
      {username, %{metas: metas}} -> %{id: username, metas: metas}
      {username, other} -> %{id: username, metas: Map.get(other, :metas)}
    end)
  end

  defp topic(incident_id), do: "incident_onlookers:#{incident_id}"

  def init(_opts), do: {:ok, %{}}

  @doc """
  Phoenix.Presence callback: handle metas. Broadcasts simple messages:
  - `{:user_joined, %{id: username, metas: metas_list}}`
  - `{:user_left, %{id: username, metas: metas_list}}`
  """
  def handle_metas(topic, %{joins: joins, leaves: leaves}, presences, state) do
    for {username, _} <- joins do
      metas = Map.get(presences, username, %{metas: []}) |> Map.get(:metas, [])

      pubsub_module().broadcast(
        HeadsUp.PubSub,
        "updates:" <> topic,
        {:user_joined, %{id: username, metas: metas}}
      )
    end

    for {username, _} <- leaves do
      metas = Map.get(presences, username, %{metas: []}) |> Map.get(:metas, [])

      pubsub_module().broadcast(
        HeadsUp.PubSub,
        "updates:" <> topic,
        {:user_left, %{id: username, metas: metas}}
      )
    end

    {:ok, state}
  end
end
