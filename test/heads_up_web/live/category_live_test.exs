defmodule HeadsUpWeb.CategoryLiveTest do
  use HeadsUpWeb.ConnCase

  import Phoenix.LiveViewTest
  import HeadsUp.CategoriesFixtures

  setup %{conn: conn} do
    user = HeadsUp.AccountsFixtures.user_fixture()
    {:ok, user} = HeadsUp.Accounts.update_user(user, %{is_admin: true})
    %{conn: log_in_user(conn, user)}
  end

  @create_attrs %{name: "some name", slug: "some slug"}
  @update_attrs %{name: "some updated name", slug: "some updated slug"}
  @invalid_attrs %{name: nil, slug: nil}
  defp create_category(_) do
    category = category_fixture()

    %{category: category}
  end

  describe "Index" do
    setup [:create_category]

    test "lists all categories", %{conn: conn, category: category} do
      {:ok, _index_live, html} = live(conn, ~p"/categories")

      assert html =~ "Listing Categories"
      assert html =~ category.name
    end

    test "saves new category", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/categories")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Category")
               |> render_click()
               |> follow_redirect(conn, ~p"/categories/new")

      assert render(form_live) =~ "New Category"

      assert form_live
             |> form("#category-form", category: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#category-form", category: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/categories")

      html = render(index_live)
      assert html =~ "Category created successfully"
      assert html =~ "some name"
    end

    test "updates category in listing", %{conn: conn, category: category} do
      {:ok, index_live, _html} = live(conn, ~p"/categories")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#categories-#{category.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/categories/#{category}/edit")

      assert render(form_live) =~ "Edit Category"

      assert form_live
             |> form("#category-form", category: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#category-form", category: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/categories")

      html = render(index_live)
      assert html =~ "Category updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes category in listing", %{conn: conn, category: category} do
      {:ok, index_live, _html} = live(conn, ~p"/categories")

      assert index_live |> element("#categories-#{category.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#categories-#{category.id}")
    end
  end

  describe "Show" do
    setup [:create_category]

    test "displays category", %{conn: conn, category: category} do
      {:ok, _show_live, html} = live(conn, ~p"/categories/#{category}")

      assert html =~ "Show Category"
      assert html =~ category.name
    end

    test "updates category and returns to show", %{conn: conn, category: category} do
      {:ok, show_live, _html} = live(conn, ~p"/categories/#{category}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/categories/#{category}/edit?return_to=show")

      assert render(form_live) =~ "Edit Category"

      assert form_live
             |> form("#category-form", category: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#category-form", category: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/categories/#{category}")

      html = render(show_live)
      assert html =~ "Category updated successfully"
      assert html =~ "some updated name"
    end

    test "displays incidents for a category", %{conn: conn, category: category} do
      # Insert an incident belonging to this category
      incident = HeadsUp.IncidentsFixtures.incident_fixture(%{category_id: category.id})

      {:ok, _show_live, html} = live(conn, ~p"/categories/#{category}")

      assert html =~ "Incidents"
      assert html =~ incident.name
      assert html =~ incident.image_path
    end
  end

  describe "Index additional coverage" do
    setup [:create_category]

    test "handles invalid create submission", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/categories/new")

      invalid_attrs = %{name: nil, slug: nil}

      assert index_live
             |> form("#category-form", category: invalid_attrs)
             |> render_submit() =~ "can&#39;t be blank"
    end

    test "handles invalid edit submission", %{conn: conn, category: category} do
      {:ok, index_live, _html} = live(conn, ~p"/categories/#{category}/edit")

      invalid_attrs = %{name: nil, slug: nil}

      assert index_live
             |> form("#category-form", category: invalid_attrs)
             |> render_submit() =~ "can&#39;t be blank"
    end

    test "return_path with show branch", %{conn: conn, category: category} do
      {:ok, show_live, _html} = live(conn, ~p"/categories/#{category}")

      assert {:ok, form_live, _html} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/categories/#{category}/edit?return_to=show")

      assert render(form_live) =~ "Edit Category"
    end

    test "handles unknown live_action safely", %{conn: conn} do
      {:ok, _live_view, html} = live(conn, ~p"/categories/new?unknown_param=true")

      # Ensure it rendered without crashing
      assert html =~ "New Category"
    end
  end
end
