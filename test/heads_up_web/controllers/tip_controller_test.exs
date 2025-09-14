defmodule HeadsUpWeb.TipControllerTest do
  use HeadsUpWeb.ConnCase, async: true

  alias HeadsUp.Tips

  describe "index/2" do
    test "lists all tips", %{conn: conn} do
      conn = get(conn, ~p"/tips")
      response = html_response(conn, 200)
      assert response =~ "Safety Tips"

      for tip <- Tips.list_tips() do
        assert response =~ tip.text
      end
    end
  end

  describe "show/2" do
    test "shows the chosen tip", %{conn: conn} do
      tip = Tips.get_tip!(1)
      conn = get(conn, ~p"/tips/#{tip.id}")
      response = html_response(conn, 200)

      assert response =~ tip.text
      # This covers the `@answer` assign from the `snoop` plug in the router
      assert response =~ ~r/You Like a tip, (Yes|No|Maybe)\?/
    end
  end
end
