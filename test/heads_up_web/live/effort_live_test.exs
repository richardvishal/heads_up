defmodule HeadsUpWeb.EffortLiveTest do
  use HeadsUpWeb.ConnCase
  import Phoenix.LiveViewTest

  test "mounts with initial state", %{conn: conn} do
    {:ok, lv, html} = live(conn, ~p"/effort")

    assert html =~ "Community Love"
    # responders
    assert render(lv) =~ "0"
    # minutes_per_responder
    assert render(lv) =~ "10"
  end

  test "adds responders", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/effort")

    lv
    |> element("button[phx-click=add][phx-value-responders=3]")
    |> render_click()

    # responders should now be 3
    assert render(lv) =~ "3"
  end

  test "recalculates minutes per responder", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/effort")

    lv
    |> form("form", %{minutes_per_responder: "20"})
    |> render_submit()

    assert render(lv) =~ "20"
  end

  test "updates responders via handle_info", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/effort")

    # manually send the message that normally comes from Process.send_after
    send(lv.pid, :update_responders)
    # allow LiveView to process
    assert render(lv) =~ "3"
  end
end
