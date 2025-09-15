defmodule HeadsUpWeb.LayoutsTest do
  use HeadsUpWeb.ConnCase, async: true

  test "renders app layout with nav links", %{conn: conn} do
    html =
      conn
      |> get(~p"/")   # any route that uses the :app layout
      |> html_response(200)

    assert html =~ "Incidents"
    assert html =~ "Efforts"
    assert html =~ "Categories"
  end

  test "renders root layout with meta tags", %{conn: conn} do
    html =
      conn
      |> get(~p"/")   # :root is used as the outer skeleton
      |> html_response(200)

    assert html =~ "<meta name=\"csrf-token\""
    assert html =~ "HeadsUp"
  end
end
