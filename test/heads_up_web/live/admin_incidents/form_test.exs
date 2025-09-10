defmodule HeadsUpWeb.AdminIncidents.FormTest do
  use HeadsUpWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import HeadsUp.DataCase
  import HeadsUp.IncidentsFixtures
  import HeadsUp.CategoriesFixtures

  alias HeadsUp.Incidents
  alias HeadsUp.Admin

  setup %{conn: conn} do
    user = HeadsUp.AccountsFixtures.user_fixture()
    {:ok, user} = HeadsUp.Accounts.update_user(user, %{is_admin: true})
    category = category_fixture(name: "Test Category")
    %{conn: log_in_user(conn, user), category: category}
  end

  describe "mount/3" do
    test "mounts new form with categories", %{conn: conn, category: category} do
      {:ok, lv, _html} = live(conn, ~p"/admin/incidents/new")
      assert has_element?(lv, "h1", "New Incident")
      assert render(lv) =~ category.name
    end

    test "mounts edit form with incident data", %{conn: conn} do
      incident = incident_fixture()
      {:ok, lv, _html} = live(conn, ~p"/admin/incidents/#{incident.id}/edit")
      assert has_element?(lv, "h1", "Edit Incident")
      assert render(lv) =~ incident.name
    end
  end

  describe "validate" do
    test "shows errors for invalid params", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/incidents/new")

      lv
      |> form("#incident-form", incident: %{name: ""})
      |> render_change()

      assert render(lv) =~ "can&#39;t be blank"
    end

    test "accepts valid params", %{conn: conn, category: category} do
      {:ok, lv, _html} = live(conn, ~p"/admin/incidents/new")

      valid_params = %{
        "name" => "Valid Incident",
        "priority" => "1",
        "status" => "pending",
        "category_id" => "#{category.id}",
        "description" => "Something happened",
        "image_path" => "/images/placeholder.jpg"
      }

      html =
        lv
        |> form("#incident-form", incident: valid_params)
        |> render_change()

      refute html =~ "can&#39;t be blank"
    end
  end

  describe "save incident" do
    test "creates a new incident on valid params", %{conn: conn, category: category} do
      {:ok, lv, _html} = live(conn, ~p"/admin/incidents/new")

      params = %{
        "name" => "Incident OK",
        "priority" => "2",
        "status" => "pending",
        "category_id" => "#{category.id}",
        "description" => "Something happened",
        "image_path" => "/images/sample.png"
      }

      {:ok, _lv, html} =
        lv
        |> form("#incident-form", incident: params)
        |> render_submit()
        |> follow_redirect(conn, ~p"/admin/incidents")

      assert html =~ "Incident created successfully"
      assert Incidents.list_incidents() |> Enum.any?(fn i -> i.name == "Incident OK" end)
    end

    test "renders errors on invalid params", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/incidents/new")

      html =
        lv
        |> form("#incident-form", incident: %{name: ""})
        |> render_submit()

      assert html =~ "can&#39;t be blank"
    end

    test "updates an incident successfully", %{conn: conn} do
      incident = incident_fixture()
      {:ok, lv, _html} = live(conn, ~p"/admin/incidents/#{incident.id}/edit")

      {:ok, _lv, html} =
        lv
        |> form("#incident-form", incident: %{name: "Updated Incident"})
        |> render_submit()
        |> follow_redirect(conn, ~p"/admin/incidents")

      assert html =~ "Incident created successfully"
      assert Admin.get_incident!(incident.id).name == "Updated Incident"
    end

    test "renders errors on failed update", %{conn: conn} do
      incident = incident_fixture()
      {:ok, lv, _html} = live(conn, ~p"/admin/incidents/#{incident.id}/edit")

      html =
        lv
        |> form("#incident-form", incident: %{name: ""})
        |> render_submit()

      assert html =~ "can&#39;t be blank"
    end
  end

  describe "edge cases" do
    test "fails when editing with non-existent id", %{conn: conn} do
      assert_error_sent :not_found, fn ->
        live(conn, ~p"/admin/incidents/999999/edit")
      end
    end

    test "fails with invalid status via changeset" do
      category = category_fixture()

      params = %{
        "name" => "Incident",
        "priority" => "1",
        "status" => "invalid-status",
        "category_id" => category.id,
        "description" => "Broken case",
        "image_path" => "/images/placeholder.jpg"
      }

      changeset = Admin.change_incident(%Incidents.Incident{}, params)
      refute changeset.valid?
      assert %{status: ["is invalid"]} = errors_on(changeset)
    end

    test "fails with non-existent category via changeset" do
      params = %{
        "name" => "Bad Incident",
        "priority" => 1,
        "status" => "pending",
        # non-existent
        "category_id" => 99999,
        "description" => "Oops happened",
        "image_path" => "/images/placeholder.jpg"
      }

      changeset = Admin.change_incident(%HeadsUp.Incidents.Incident{}, params)

      # Try inserting to trigger assoc_constraint
      assert {:error, changeset} = HeadsUp.Repo.insert(changeset)
      assert %{category: ["does not exist"]} = errors_on(changeset)
    end

    test "fails when description is too short", %{conn: conn, category: category} do
      {:ok, lv, _html} = live(conn, ~p"/admin/incidents/new")

      params = %{
        "name" => "Short Desc",
        "priority" => "1",
        "status" => "pending",
        "category_id" => "#{category.id}",
        "description" => "Short",
        "image_path" => "/images/placeholder.jpg"
      }

      html =
        lv
        |> form("#incident-form", incident: params)
        |> render_submit()

      assert html =~ "should be at least 10 character(s)"
    end
  end
end
