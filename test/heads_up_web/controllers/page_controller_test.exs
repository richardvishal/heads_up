defmodule HeadsUpWeb.PageControllerTest do
  use HeadsUpWeb.ConnCase, async: true

  test "GET / calls home/2", %{conn: conn} do
    conn = get(conn, ~p"/")

    # check for logo or any static content
    assert html_response(conn, 200) =~ "heads-up-logo.png"

    # or check for a link that exists in the layout
    assert html_response(conn, 200) =~ "Register"
    assert html_response(conn, 200) =~ "Log in"
  end
end
