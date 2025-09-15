defmodule HeadsUpWeb.Incidents.ShowTest do
  use HeadsUpWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Mox
  import HeadsUp.IncidentsFixtures
  import HeadsUp.AccountsFixtures
  import HeadsUp.ResponsesFixtures

  setup :verify_on_exit!

  setup do
    # Default stubs so tests don’t fail with strict counts
    stub(HeadsUp.IncidentsMock, :urgent_incidents, fn _incident ->
      {:ok, %{urgent_incidents: []}}
    end)

    stub(PhoenixPubSubMock, :subscribe, fn _, _ -> :ok end)
    stub(PhoenixPubSubMock, :broadcast, fn _, _, _ -> :ok end)

    :ok
  end

  describe "Show incident" do
    test "displays incident details", %{conn: conn} do
      incident = incident_fixture()

      expect(PhoenixPresenceMock, :list, 2, fn _ -> %{} end)

      {:ok, view, _html} =
        conn
        |> get(~p"/incidents/#{incident.id}")
        |> live()

      assert has_element?(view, "h2", incident.name)
      assert has_element?(view, ".description", incident.description)
      assert view |> element(".badge") |> render() =~ Atom.to_string(incident.status)
      assert has_element?(view, ".priority", Integer.to_string(incident.priority))
    end

    test "allows a logged-in user to post a response", %{conn: conn} do
      user = user_fixture()
      incident = incident_fixture()

      expect(PhoenixPresenceMock, :list, 2, fn _topic -> %{} end)
      expect(PhoenixPresenceMock, :track, fn _pid, _topic, _user, _meta -> {:ok, %{}} end)

      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> get(~p"/incidents/#{incident.id}")
        |> live()

      assert has_element?(view, "form#response-form")

      view
      |> form("#response-form", response: %{status: "enroute", note: "On my way!"})
      |> render_submit()

      assert has_element?(view, "#responses .response", "On my way!")
      assert has_element?(view, "#responses .response", "enroute")
    end

    test "updates in real-time when a new response is posted", %{conn: conn} do
      incident = incident_fixture()

      expect(PhoenixPresenceMock, :list, 2, fn _ -> %{} end)

      {:ok, view, _html} =
        conn
        |> get(~p"/incidents/#{incident.id}")
        |> live()

      refute has_element?(view, "#responses .response")

      response = response_fixture(%{incident: incident})

      # Simulate broadcast
      HeadsUp.Incidents.broadcast(incident.id, {:new_response, response})

      assert has_element?(view, "#responses .response", response.note)
    end

    test "shows an error when submitting an invalid response", %{conn: conn} do
      user = user_fixture()
      incident = incident_fixture()

      expect(PhoenixPresenceMock, :list, 2, fn _ -> %{} end)
      expect(PhoenixPresenceMock, :track, fn _, _, _, _ -> {:ok, %{}} end)

      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> get(~p"/incidents/#{incident.id}")
        |> live()

      html =
        view
        |> form("#response-form", response: %{status: "enroute", note: ""})
        |> render_submit()

      assert html =~ "can&#39;t be blank"
    end

    test "validates response form data", %{conn: conn} do
      user = user_fixture()
      incident = incident_fixture()

      expect(PhoenixPresenceMock, :list, 2, fn _ -> %{} end)
      expect(PhoenixPresenceMock, :track, fn _, _, _, _ -> {:ok, %{}} end)

      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> get(~p"/incidents/#{incident.id}")
        |> live()

      html =
        view
        |> form("#response-form", response: %{status: "enroute", note: ""})
        |> render_change()

      assert html =~ "can&#39;t be blank"
    end

    test "updates onlookers when a user joins", %{conn: conn} do
      incident = incident_fixture()

      expect(PhoenixPresenceMock, :list, 2, fn _ -> %{} end)

      {:ok, view, _html} = live(conn, ~p"/incidents/#{incident.id}")

      refute has_element?(view, "#onlookers li", "testuser")

      HeadsUp.Incidents.broadcast(incident.id, {:user_joined, %{id: "testuser", metas: [%{}]}})

      assert has_element?(view, "#onlookers li", "testuser")
    end

    test "updates incident details when incident is updated", %{conn: conn} do
      incident = incident_fixture(%{status: :pending})

      expect(PhoenixPresenceMock, :list, 2, fn _ -> %{} end)

      {:ok, view, _html} = live(conn, ~p"/incidents/#{incident.id}")

      {:ok, _updated_incident} = HeadsUp.Admin.update_incident(incident, %{status: :resolved})

      assert view |> element(".badge") |> render() =~ "resolved"
    end

    test "updates onlookers when a user leaves", %{conn: conn} do
      incident = incident_fixture()

      expect(PhoenixPresenceMock, :list, 2, fn _ -> %{"testuser" => %{metas: [%{}]}} end)

      {:ok, view, _html} = live(conn, ~p"/incidents/#{incident.id}")

      assert has_element?(view, "#onlookers li", "testuser")

      HeadsUp.Incidents.broadcast(incident.id, {:user_left, %{id: "testuser", metas: []}})

      refute has_element?(view, "#onlookers li", "testuser")
    end

    test "updates onlookers when a user with multiple sessions leaves one", %{conn: conn} do
      incident = incident_fixture()

      expect(PhoenixPresenceMock, :list, 2, fn _ -> %{"testuser" => %{metas: [%{}, %{}]}} end)

      {:ok, view, _html} = live(conn, ~p"/incidents/#{incident.id}")

      assert has_element?(view, "#onlookers li", "testuser (2)")

      HeadsUp.Incidents.broadcast(incident.id, {:user_left, %{id: "testuser", metas: [%{}]}})

      assert has_element?(view, "#onlookers li", "testuser (1)")
    end

    test "displays heroic response when present", %{conn: conn} do
      user = user_fixture(username: "SuperCoder")
      incident = incident_fixture(%{status: :resolved})
      response = response_fixture(%{incident: incident, user: user, note: "I fixed it!"})

      {:ok, incident} =
        HeadsUp.Admin.update_incident(incident, %{heroic_response_id: response.id})

      expect(PhoenixPresenceMock, :list, 2, fn _ -> %{} end)

      {:ok, view, _html} =
        conn
        |> get(~p"/incidents/#{incident.id}")
        |> live()

      assert has_element?(view, ".headline", "Heroic Responder: SuperCoder")
      assert has_element?(view, ".headline .tagline", "I fixed it!")
    end

    test "displays async error for urgent incidents", %{conn: conn} do
      incident = incident_fixture()

      expect(PhoenixPresenceMock, :list, 2, fn _ -> %{} end)

      stub(HeadsUp.IncidentsMock, :urgent_incidents, fn _ -> {:error, "Database down"} end)

      {:ok, view, _html} = live(conn, ~p"/incidents/#{incident.id}")

      assert render_async(view) =~ "Uhh oh! Database down"
    end

    test "renders urgent incidents when present", %{conn: conn} do
      incident = incident_fixture()

      expect(PhoenixPresenceMock, :list, 2, fn _ -> %{} end)
      # Allow subscribe/2 to be called 0 or more times
      stub(PhoenixPubSubMock, :subscribe, fn _, _ -> :ok end)

      # Mock urgent incidents to return a list
      stub(HeadsUp.IncidentsMock, :urgent_incidents, fn _ ->
        {:ok, %{urgent_incidents: [incident]}}
      end)

      {:ok, view, _html} = live(conn, ~p"/incidents/#{incident.id}")

      assert render_async(view) =~ incident.name
    end
  end
end
