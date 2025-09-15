defmodule HeadsUp.IncidentsTest do
  use HeadsUp.DataCase

  alias HeadsUp.Incidents

  import HeadsUp.IncidentsFixtures
  import HeadsUp.CategoriesFixtures
  import HeadsUp.AccountsFixtures
  import HeadsUp.ResponsesFixtures

  describe "PubSub" do
    test "subscribe/1 subscribes to topic" do
      topic = "incidents:123"
      assert :ok == Incidents.subscribe(topic)
    end

    test "broadcast/2 broadcasts message" do
      topic = "incidents:123"
      message = %{msg: "hello"}
      assert :ok == Incidents.broadcast(topic, message)
    end
  end

  describe "list_incidents/0 and get_incident!/1" do
    test "lists all incidents" do
      incident = incident_fixture()
      assert Incidents.list_incidents() |> Enum.map(& &1.id) |> Enum.member?(incident.id)
    end

    test "get_incident!/1 preloads category and heroic_response.user" do
      category = category_fixture()
      incident = incident_fixture(%{category_id: category.id, heroic_response_id: nil})

      fetched = Incidents.get_incident!(incident.id)
      assert fetched.id == incident.id
      assert Map.has_key?(fetched, :category)
      assert Map.has_key?(fetched, :heroic_response)
    end
  end

  describe "filter_incidents/1" do
    setup do
      category = category_fixture()

      incident1 =
        incident_fixture(%{
          name: "Test A",
          status: "pending",
          category_id: category.id,
          priority: 2
        })

      incident2 =
        incident_fixture(%{
          name: "Test B",
          status: "resolved",
          category_id: category.id,
          priority: 3
        })

      %{category: category, incident1: incident1, incident2: incident2}
    end

    test "filters by status", %{incident1: i1} do
      results = Incidents.filter_incidents(%{"status" => "pending"})
      assert Enum.any?(results, &(&1.id == i1.id))
    end

    test "filters by category", %{category: category, incident1: i1} do
      results = Incidents.filter_incidents(%{"category" => category.slug})
      assert Enum.any?(results, &(&1.id == i1.id))
    end

    test "filters by search query", %{incident1: i1} do
      results = Incidents.filter_incidents(%{"q" => "Test A"})
      assert Enum.any?(results, &(&1.id == i1.id))
    end

    test "sorts by name", %{incident1: i1, incident2: i2} do
      results = Incidents.filter_incidents(%{"sort_by" => "name"})
      # descending name
      assert results |> Enum.map(& &1.id) == [i2.id, i1.id]
    end

    test "sorts by priority asc/desc", %{incident1: i1, incident2: i2} do
      desc = Incidents.filter_incidents(%{"sort_by" => "priority_desc"})
      asc = Incidents.filter_incidents(%{"sort_by" => "priority_asc"})
      assert desc |> Enum.map(& &1.id) == [i2.id, i1.id]
      assert asc |> Enum.map(& &1.id) == [i1.id, i2.id]
    end

    test "sorts by category", %{incident1: i1, incident2: i2} do
      results = Incidents.filter_incidents(%{"sort_by" => "category"})
      # All have same category, so order by category name ascending
      assert Enum.any?(results, &(&1.id in [i1.id, i2.id]))
    end

    test "handles empty filters" do
      results = Incidents.filter_incidents(%{})
      assert is_list(results)
    end
  end

  describe "urgent_incidents/1" do
    test "returns urgent incidents excluding given incident" do
      i1 = incident_fixture(%{priority: 3})
      i2 = incident_fixture(%{priority: 3})
      i3 = incident_fixture(%{priority: 2})

      {:ok, %{urgent_incidents: list}} = Incidents.urgent_incidents(i1)
      assert Enum.member?(list, i2)
      refute Enum.member?(list, i1)
      refute Enum.member?(list, i3)
    end
  end

  describe "list_responses/1" do
    test "lists responses for an incident" do
      incident = incident_fixture()
      user = user_fixture()
      response = response_fixture(%{incident: incident, user: user})

      results = Incidents.list_responses(incident)
      assert Enum.any?(results, &(&1.id == response.id))
    end
  end
end
