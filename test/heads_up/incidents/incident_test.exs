defmodule HeadsUp.Incidents.IncidentTest do
  use HeadsUp.DataCase

  alias HeadsUp.Incidents.Incident
  alias HeadsUp.CategoriesFixtures
  alias HeadsUp.Repo

  describe "changeset/2" do
    setup do
      category = CategoriesFixtures.category_fixture()
      %{category: category}
    end

    test "validates required fields", %{category: _category} do
      changeset = Incident.changeset(%Incident{}, %{})
      refute changeset.valid?

      assert %{
               name: ["can't be blank"],
               description: ["can't be blank"],
               category_id: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "description must be at least 10 characters", %{category: category} do
      attrs = %{name: "Test", description: "short", category_id: category.id}
      changeset = Incident.changeset(%Incident{}, attrs)

      refute changeset.valid?
      assert %{description: ["should be at least 10 character(s)"]} = errors_on(changeset)
    end

    test "valid priorities pass validation", %{category: category} do
      for priority <- 1..3 do
        attrs = %{
          priority: priority,
          name: "Test",
          description: "Long enough description",
          category_id: category.id
        }

        changeset = Incident.changeset(%Incident{}, attrs)
        refute errors_on(changeset)[:priority]
      end
    end

    test "invalid priorities add an error", %{category: category} do
      for priority <- [0, 4] do
        attrs = %{
          priority: priority,
          name: "Test",
          description: "This is a long enough description",
          status: :pending,
          image_path: "/images/placeholder.jpg",
          category_id: category.id
        }

        changeset = Incident.changeset(%Incident{}, attrs)
        assert %{priority: ["Priority should be between 1 and 3"]} = errors_on(changeset)
      end
    end

    test "defaults are applied when not provided", %{category: category} do
      attrs = %{
        name: "Test Incident",
        description: "Long enough description",
        category_id: category.id
      }

      changeset = Incident.changeset(%Incident{}, attrs)

      assert get_field(changeset, :priority) == 1
      assert get_field(changeset, :status) == :pending
      assert get_field(changeset, :image_path) == "/images/placeholder.jpg"
    end

    test "assoc_constraint triggers error for non-existing category" do
      attrs = %{
        name: "Test Incident",
        description: "Long enough description",
        category_id: -1
      }

      changeset = Incident.changeset(%Incident{}, attrs)
      assert changeset.valid?

      {:error, changeset} = Repo.insert(changeset)
      assert %{category: ["does not exist"]} = errors_on(changeset)
    end

    test "validate_priority fallback clause is executed when priority not in changes", %{
      category: category
    } do
      # Create an empty struct without :priority
      incident = %Incident{}

      changeset =
        Incident.changeset(incident, %{
          name: "Test Incident",
          description: "Long enough description",
          category_id: category.id
        })

      # Should still be valid (fallback clause executed)
      assert changeset.valid?
    end

    test "invalid status adds an error", %{category: category} do
      attrs = %{
        name: "Test Incident",
        description: "Long enough description",
        category_id: category.id,
        status: :invalid_status
      }

      changeset = Incident.changeset(%Incident{}, attrs)
      refute changeset.valid?
      assert %{status: ["is invalid"]} = errors_on(changeset)
    end

    test "is valid when heroic_response_id is provided", %{category: category} do
      response = HeadsUp.ResponsesFixtures.response_fixture()

      attrs = %{
        name: "Test Incident",
        description: "Long enough description",
        category_id: category.id,
        heroic_response_id: response.id
      }

      changeset = Incident.changeset(%Incident{}, attrs)
      assert changeset.valid?
      assert get_field(changeset, :heroic_response_id) == response.id
    end

    test "assoc_constraint triggers error for non-existing heroic_response", %{
      category: category
    } do
      attrs = %{
        name: "Test Incident",
        description: "Long enough description",
        category_id: category.id,
        heroic_response_id: -1
      }

      changeset = Incident.changeset(%Incident{}, attrs)
      {:error, changeset} = Repo.insert(changeset)
      assert %{heroic_response: ["does not exist"]} = errors_on(changeset)
    end
  end
end
