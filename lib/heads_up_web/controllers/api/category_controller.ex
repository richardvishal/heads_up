defmodule HeadsUpWeb.Api.CategoryController do
  alias HeadsUp.Categories

  use HeadsUpWeb, :controller

  def show(conn, %{"id" => id}) do
    render(conn, %{category: Categories.get_category_with_incidents!(id)})
  end
end
