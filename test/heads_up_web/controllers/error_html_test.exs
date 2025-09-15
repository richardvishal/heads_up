defmodule HeadsUpWeb.ErrorHTMLTest do
  use ExUnit.Case, async: true
  alias HeadsUpWeb.ErrorHTML

  describe "render/2" do
    test "renders 404.html directly" do
      assert ErrorHTML.render("404.html", %{}) == "Not Found"
    end

    test "renders 500.html directly" do
      assert ErrorHTML.render("500.html", %{}) == "Internal Server Error"
    end

    test "renders other error codes" do
      assert ErrorHTML.render("401.html", %{}) == "Unauthorized"
      assert ErrorHTML.render("403.html", %{}) == "Forbidden"
    end
  end
end
