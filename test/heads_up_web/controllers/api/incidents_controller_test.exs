defmodule HeadsUpWeb.Api.IncidentsControllerTest do
  use HeadsUpWeb.ConnCase, async: true

  import HeadsUp.IncidentsFixtures
  import HeadsUp.CategoriesFixtures

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all incidents", %{conn: conn} do
      conn = get(conn, ~p"/api/incidents")
      assert json_response(conn, 200) == %{"incidents" => []}

      incident_fixture()
      conn = get(conn, ~p"/api/incidents")
      assert length(json_response(conn, 200)["incidents"]) == 1
    end
  end

  describe "create incident" do
    test "renders incident when data is valid", %{conn: conn} do
      category = category_fixture()

      create_attrs = %{
        "name" => "some name",
        "description" => "a very long and valid description",
        "priority" => 1,
        "category_id" => category.id,
        "status" => "pending",
        "image_path" => "/images/placeholder.jpg"
      }

      conn = post(conn, ~p"/api/incidents", incident: create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["incident"]

      conn = get(conn, ~p"/api/incidents/#{id}")

      assert %{
               "id" => ^id,
               "name" => "some name",
               "status" => "pending"
             } = json_response(conn, 200)["incident"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/incidents", incident: %{"name" => nil})
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "show incident" do
    setup do
      %{incident: incident_fixture()}
    end

    test "renders incident", %{conn: conn, incident: incident} do
      conn = get(conn, ~p"/api/incidents/#{incident}")
      response = json_response(conn, 200)
      assert response["incident"]["id"] == incident.id
    end

    test "renders 404 when incident does not exist", %{conn: conn} do
      conn = get(conn, ~p"/api/incidents/#{-1}")
      assert response(conn, 404)
    end
  end
end
