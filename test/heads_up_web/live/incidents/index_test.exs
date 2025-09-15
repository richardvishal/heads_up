defmodule HeadsUpWeb.Incidents.IndexTest do
  use HeadsUpWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import HeadsUp.IncidentsFixtures
  import HeadsUp.CategoriesFixtures

  describe "Incident Index" do
    setup do
      # Create categories
      category1 = category_fixture(%{name: "Network", slug: "network"})
      category2 = category_fixture(%{name: "Database", slug: "database"})

      # Create incidents
      incident1 =
        incident_fixture(%{
          name: "Internet down",
          category: category1,
          status: :pending,
          priority: 1
        })

      incident2 =
        incident_fixture(%{
          name: "DB connection error",
          category: category2,
          status: :resolved,
          priority: 2
        })

      %{categories: [category1, category2], incidents: [incident1, incident2]}
    end

    test "mount renders page with incident cards", %{conn: conn, incidents: [i1, i2]} do
      {:ok, _lv, html} = live(conn, ~p"/incidents")

      assert html =~ i1.name
      assert html =~ i2.name
      assert html =~ Atom.to_string(i1.status)
      assert html =~ Atom.to_string(i2.status)
    end

    test "filters by status via phx-change", %{conn: conn, incidents: [i1, _]} do
      {:ok, lv, _html} = live(conn, ~p"/incidents")

      lv
      |> form("#filter-form", %{status: "pending"})
      |> render_change()

      assert has_element?(lv, "div.incidents", i1.name)
    end

    test "filters by category via phx-submit", %{
      conn: conn,
      categories: [_, c2],
      incidents: [_, i2]
    } do
      {:ok, lv, _html} = live(conn, ~p"/incidents")

      lv
      |> form("#filter-form", %{category: c2.slug})
      |> render_submit()

      assert has_element?(lv, "div.incidents", i2.name)
    end

    test "search query filters incidents", %{conn: conn, incidents: [i1, _]} do
      {:ok, lv, _html} = live(conn, ~p"/incidents")

      lv
      |> form("#filter-form", %{q: "Internet"})
      |> render_change()

      assert has_element?(lv, "div.incidents", i1.name)
    end

    test "reset link clears filters", %{conn: conn, incidents: [i1, i2]} do
      {:ok, lv, _html} = live(conn, ~p"/incidents?status=pending&category=network")

      # Click reset link
      lv |> element("a", "Reset") |> render_click()

      # Now the no-results div should be hidden
      no_results_div = lv |> element("div#empty") |> render()
      assert no_results_div =~ "hidden"

      # Also, incident cards should be rendered
      assert has_element?(lv, "div.incidents", i1.name)
      assert has_element?(lv, "div.incidents", i2.name)
    end

    test "edge case: empty incident list shows no results message" do
      {:ok, lv, html} = live(build_conn(), ~p"/incidents?status=canceled")
      assert html =~ "No incidents found. Try adjusting your filters."
      assert has_element?(lv, "div#empty")
    end

    test "edge case: filter params are case-insensitive and partial matches", %{
      conn: conn,
      incidents: [i1, _]
    } do
      {:ok, lv, _html} = live(conn, ~p"/incidents")

      lv
      |> form("#filter-form", %{q: "internet"})
      |> render_change()

      assert has_element?(lv, "div.incidents", i1.name)
    end

    test "edge case: invalid filter params handled gracefully", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/incidents?status=unknown&category=invalid")
      assert has_element?(lv, "div#empty")
    end

    test "submitting filter form triggers a patch", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/incidents")

      view
      |> form("#filter-form", %{status: "pending"})
      |> render_submit()

      assert_patched(view, ~p"/incidents?status=pending")
    end

    test "displays headline when assigned", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/incidents")

      refute render(view) =~ "25 Incidents Resolved This Month!"

      view
      |> element("button", "Show Headline")
      |> render_click()

      assert render(view) =~ "25 Incidents Resolved This Month!"
    end
  end
end
