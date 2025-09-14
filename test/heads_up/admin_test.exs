defmodule HeadsUp.AdminTest do
  use HeadsUp.DataCase

  alias HeadsUp.Admin
  import HeadsUp.CategoriesFixtures
  import HeadsUp.IncidentsFixtures
  import HeadsUp.ResponsesFixtures

  describe "incidents" do
    alias HeadsUp.Incidents.Incident

    @invalid_attrs %{name: nil}

    test "create_incident/1 with valid data creates an incident" do
      category = category_fixture()
      valid_attrs = %{name: "some name", description: "some description", priority: 1, category_id: category.id}

      assert {:ok, %Incident{} = incident} = Admin.create_incident(valid_attrs)
      assert incident.name == "some name"
      assert incident.description == "some description"
      assert incident.priority == 1
    end

    test "create_incident/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Admin.create_incident(@invalid_attrs)
    end

    test "delete_incident/1 deletes the incident" do
      incident = incident_fixture()
      assert {:ok, %Incident{}} = Admin.delete_incident(incident)
      assert_raise Ecto.NoResultsError, fn -> Admin.get_incident!(incident.id) end
    end
  end

  describe "draw_heroic_response/1" do
    test "returns error if incident is not resolved" do
      incident = incident_fixture()
      assert {:error, "Incident must be resolved to draw a heroic response!"} = Admin.draw_heroic_response(incident)
    end

    test "returns error if there are no responses" do
      incident = incident_fixture(%{status: :resolved})
      assert {:error, "No responses to draw!"} = Admin.draw_heroic_response(incident)
    end

    test "draws a heroic response when incident is resolved and has responses" do
      incident = incident_fixture(%{status: :resolved})
      response = response_fixture(%{incident: incident})

      {:ok, updated_incident} = Admin.draw_heroic_response(incident)
      assert updated_incident.id == incident.id
      assert updated_incident.heroic_response_id == response.id
    end
  end
end
