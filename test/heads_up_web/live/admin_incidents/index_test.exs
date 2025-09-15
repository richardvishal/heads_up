defmodule HeadsUpWeb.AdminIncidents.IndexTest do
  use HeadsUpWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  import HeadsUpWeb.ConnCase
  import HeadsUp.IncidentsFixtures
  import HeadsUp.ResponsesFixtures
  alias HeadsUp.Admin

  setup %{conn: conn} do
    # create a test user and mark as admin
    user = HeadsUp.AccountsFixtures.user_fixture()
    {:ok, user} = HeadsUp.Accounts.update_user(user, %{is_admin: true})

    # create a test incident
    incident = incident_fixture()

    # return conn logged in and current_user
    %{conn: log_in_user(conn, user), incident: incident, current_user: user}
  end

  describe "delete incident" do
    test "delete removes incident from list", %{conn: conn, incident: incident} do
      {:ok, view, _html} = live(conn, ~p"/admin/incidents")

      # click delete for the specific incident
      view
      |> element("a[data-role='delete-incident-#{incident.id}']")
      |> render_click()

      # assert the incident is gone from HTML
      refute has_element?(view, "#incidents-#{incident.id}")
    end
  end

  describe "draw heroic response" do
    test "shows error if unresolved", %{conn: conn, incident: incident} do
      {:ok, view, _html} = live(conn, ~p"/admin/incidents")

      # click draw-response for this unresolved incident
      view
      |> element("a[phx-click='draw-response'][phx-value-id='#{incident.id}']")
      |> render_click()

      # assert flash error is rendered
      assert render(view) =~ "Incident must be resolved to draw a heroic response!"
    end

    test "shows error if no responses", %{conn: conn, incident: incident} do
      # mark incident as resolved
      {:ok, incident} = Admin.update_incident(incident, %{status: :resolved})

      {:ok, view, _html} = live(conn, ~p"/admin/incidents")

      # click draw-response for incident with no heroic responses
      view
      |> element("a[phx-click='draw-response'][phx-value-id='#{incident.id}']")
      |> render_click()
      assert render(view) =~ "No responses to draw!"
    end

    test "draws a heroic response when available", %{conn: conn, incident: incident} do
      # mark incident resolved and add a heroic response
      {:ok, incident} = Admin.update_incident(incident, %{status: :resolved})
      response_fixture(%{incident: incident})

      {:ok, view, _html} = live(conn, ~p"/admin/incidents")

      # click draw-response
      view
      |> element("a[phx-click='draw-response'][phx-value-id='#{incident.id}']")
      |> render_click()

      # assert flash success
      assert render(view) =~ "Heroic response drawn!"
    end
  end
end
