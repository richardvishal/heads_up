defmodule HeadsUpWeb.PresenceTest do
  use ExUnit.Case, async: false
  import Mox

  alias HeadsUpWeb.Presence

  # Minimal behaviour clauses are already defined in lib/heads_up_web/presence_behaviours.ex

  setup :verify_on_exit!

  setup do
    %{
      user: %{username: "test_user"},
      incident_id: "incident_123"
    }
  end

  test "track_user/2 calls Presence.track with correct arguments and returns :ok", %{
    user: user,
    incident_id: id
  } do
    expect(PhoenixPresenceMock, :track, fn _pid, topic, username, metas ->
      assert topic == "incident_onlookers:#{id}"
      assert username == user.username
      assert metas[:online_at] != nil
      {:ok, %{}}
    end)

    assert {:ok, _} = Presence.track_user(id, user)
  end

  test "track_user/2 returns error when Presence.track fails", %{user: user, incident_id: id} do
    expect(PhoenixPresenceMock, :track, fn _pid, _topic, _username, _metas ->
      {:error, :not_alive}
    end)

    assert {:error, :not_alive} = Presence.track_user(id, user)
  end

  test "subscribe/1 calls Phoenix.PubSub.subscribe with the correct topic", %{incident_id: id} do
    expect(PhoenixPubSubMock, :subscribe, fn server, topic ->
      assert server == HeadsUp.PubSub
      assert topic == "updates:incident_onlookers:#{id}"
      :ok
    end)

    assert :ok = Presence.subscribe(id)
  end

  test "subscribe/1 returns error if PubSub fails", %{incident_id: id} do
    expect(PhoenixPubSubMock, :subscribe, fn _server, _topic ->
      {:error, :disconnected}
    end)

    assert {:error, :disconnected} = Presence.subscribe(id)
  end

  test "list_presences/1 returns a formatted list of presences", %{incident_id: id} do
    presences = %{
      "user1" => %{metas: [%{online_at: 1000}, %{online_at: 1001}]},
      "user2" => %{metas: [%{online_at: 2000}]}
    }

    expect(PhoenixPresenceMock, :list, fn topic ->
      assert topic == "incident_onlookers:#{id}"
      presences
    end)

    assert Presence.list_presences(id) == [
             %{id: "user1", metas: [%{online_at: 1000}, %{online_at: 1001}]},
             %{id: "user2", metas: [%{online_at: 2000}]}
           ]
  end

  test "list_presences/1 returns an empty list when no presences are found", %{incident_id: id} do
    expect(PhoenixPresenceMock, :list, fn _ -> %{} end)

    assert Presence.list_presences(id) == []
  end

  test "list_presences/1 handles unexpected presence data", %{incident_id: id} do
    expect(PhoenixPresenceMock, :list, fn _ -> %{"weird" => %{}} end)
    assert Presence.list_presences(id) == [%{id: "weird", metas: nil}]
  end

  test "handle_metas/4 broadcasts a user_joined message for new joins", %{incident_id: id} do
    joins = %{"new_user" => %{metas: [%{online_at: 3000}]}}
    leaves = %{}
    presences = %{"new_user" => %{metas: [%{online_at: 3000}]}}

    expect(PhoenixPubSubMock, :broadcast, fn server, topic, message ->
      assert server == HeadsUp.PubSub
      assert topic == "updates:incident_onlookers:#{id}"
      assert message == {:user_joined, %{id: "new_user", metas: [%{online_at: 3000}]}}
      :ok
    end)

    {:ok, _} =
      Presence.handle_metas(
        "incident_onlookers:#{id}",
        %{joins: joins, leaves: leaves},
        presences,
        %{}
      )
  end

  test "handle_metas/4 broadcasts a user_left message for leaves", %{incident_id: id} do
    joins = %{}
    leaves = %{"old_user" => %{}}
    presences = %{"old_user" => %{metas: [%{online_at: 1234}]}}

    expect(PhoenixPubSubMock, :broadcast, fn server, topic, message ->
      assert server == HeadsUp.PubSub
      assert topic == "updates:incident_onlookers:#{id}"
      assert message == {:user_left, %{id: "old_user", metas: [%{online_at: 1234}]}}
      :ok
    end)

    {:ok, _} =
      Presence.handle_metas(
        "incident_onlookers:#{id}",
        %{joins: joins, leaves: leaves},
        presences,
        %{}
      )
  end

  test "handle_metas/4 broadcasts a user_left message with empty metas if user is not in presence map",
       %{incident_id: id} do
    joins = %{}
    leaves = %{"user_not_present" => %{}}
    presences = %{}

    expect(PhoenixPubSubMock, :broadcast, fn server, topic, message ->
      assert server == HeadsUp.PubSub
      assert topic == "updates:incident_onlookers:#{id}"
      assert message == {:user_left, %{id: "user_not_present", metas: []}}
      :ok
    end)

    {:ok, _} =
      Presence.handle_metas(
        "incident_onlookers:#{id}",
        %{joins: joins, leaves: leaves},
        presences,
        %{}
      )
  end

  test "handle_metas/4 does not broadcast when there are no joins or leaves" do
    {:ok, _} =
      Presence.handle_metas("incident_onlookers:123", %{joins: %{}, leaves: %{}}, %{}, %{})

    # No expectations should be hit here
  end

  test "handle_metas/4 handles a mix of joins and leaves" do
    joins = %{"user_A" => %{metas: [%{}]}}
    leaves = %{"user_B" => %{}}
    presences = %{"user_A" => %{metas: [%{}]}}

    expect(PhoenixPubSubMock, :broadcast, 2, fn _server, _topic, message ->
      case message do
        {:user_joined, %{id: "user_A"}} -> :ok
        {:user_left, %{id: "user_B"}} -> :ok
        _ -> flunk("Unexpected message broadcasted")
      end
    end)

    {:ok, _} =
      Presence.handle_metas(
        "incident_onlookers:456",
        %{joins: joins, leaves: leaves},
        presences,
        %{}
      )
  end

  test "handle_metas/4 handles multiple joins and leaves" do
    joins = %{
      "userA" => %{metas: [%{online_at: 100}]},
      "userB" => %{metas: [%{online_at: 200}]}
    }

    leaves = %{"userC" => %{}, "userD" => %{}}

    presences = %{
      "userA" => %{metas: [%{online_at: 100}]},
      "userB" => %{metas: [%{online_at: 200}]},
      "userC" => %{metas: [%{online_at: 300}]}
    }

    expect(PhoenixPubSubMock, :broadcast, 4, fn _server, _topic, msg ->
      assert msg in [
               {:user_joined, %{id: "userA", metas: [%{online_at: 100}]}},
               {:user_joined, %{id: "userB", metas: [%{online_at: 200}]}},
               {:user_left, %{id: "userC", metas: [%{online_at: 300}]}},
               {:user_left, %{id: "userD", metas: []}}
             ]

      :ok
    end)

    {:ok, _} =
      Presence.handle_metas(
        "incident_onlookers:999",
        %{joins: joins, leaves: leaves},
        presences,
        %{}
      )
  end
end
