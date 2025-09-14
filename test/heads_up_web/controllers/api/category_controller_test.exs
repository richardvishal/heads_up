defmodule HeadsUpWeb.Api.CategoryControllerTest do
  use HeadsUpWeb.ConnCase, async: true

  import HeadsUp.CategoriesFixtures
  import HeadsUp.IncidentsFixtures

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "show" do
    test "lists all incidents for a category", %{conn: conn} do
      category = category_fixture()
      incident1 = incident_fixture(%{category: category, name: "Incident 1"})
      incident2 = incident_fixture(%{category: category, name: "Incident 2"})
      # This incident should NOT appear in the results
      incident_fixture(%{name: "Other Incident"})

      conn = get(conn, ~p"/api/categories/#{category.id}/incidents")
      response = json_response(conn, 200)

      assert length(response["incidents"]) == 2

      incident_ids = Enum.map(response["incidents"], & &1["id"])
      assert incident1.id in incident_ids
      assert incident2.id in incident_ids

      assert response["id"] == category.id
      assert response["name"] == category.name
      assert response["slug"] == category.slug
    end

    test "returns empty list for category with no incidents", %{conn: conn} do
      category = category_fixture()

      conn = get(conn, ~p"/api/categories/#{category.id}/incidents")
      assert json_response(conn, 200)["incidents"] == []
    end

    test "returns 404 for non-existent category", %{conn: conn} do
      assert_error_sent :not_found, fn -> get(conn, ~p"/api/categories/#{-1}/incidents") end
    end
  end
end
