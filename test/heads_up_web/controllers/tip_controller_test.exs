defmodule HeadsUpWeb.TipControllerTest do
  use HeadsUpWeb.ConnCase, async: true

  alias HeadsUp.Tips
  alias HeadsUpWeb.Router

  describe "index/2" do
    test "lists all tips with emojis", %{conn: conn} do
      conn = get(conn, ~p"/tips")
      response = html_response(conn, 200)

      # heading from index.html.heex
      assert response =~ "Safety Tips"

      # emojis assign should be rendered
      assert response =~ "❤️❤️❤️❤️❤️" or response =~ "💙💙💙💙💙" or response =~ "💜💜💜💜💜"

      # check that every seeded tip is listed
      for tip <- Tips.list_tips() do
        assert response =~ tip.text
      end
    end
  end

  describe "show/2" do
    test "shows the chosen tip with default assigns", %{conn: conn} do
      tip = Tips.get_tip!(1)

      conn = get(conn, ~p"/tips/#{tip.id}")
      response = html_response(conn, 200)

      # Tip text should appear
      assert response =~ tip.text

      # @answer assign from snoop plug
      assert response =~ ~r/You Like a tip, (Yes|No|Maybe)\?/
    end

    test "renders show for different @answer values", %{conn: conn} do
      tip = Tips.get_tip!(1)

      for answer <- ["Yes", "No", "Maybe"] do
        conn = get(conn, ~p"/tips/#{tip.id}?answer=#{answer}")
        response = html_response(conn, 200)

        assert response =~ "You Like a tip, #{answer}?"
        assert response =~ tip.text
      end
    end

    test "show/2 returns 404 for nonexistent tip", %{conn: conn} do
      conn = get(conn, ~p"/tips/-1")
      assert conn.status == 404
    end
  end

  describe "snoop/2 plug" do
    test "assigns a random answer", %{conn: conn} do
      # ensure params are fetched (avoid Unfetched error)
      conn = %{conn | params: %{}}

      conn = Router.snoop(conn, [])

      assert conn.assigns[:answer] in ["Yes", "No", "Maybe"]
    end
  end
end
