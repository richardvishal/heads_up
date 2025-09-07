defmodule HeadsUpWeb.Api.CategoryJSON do
  def show(%{category: category}) do
    %{
      id: category.id,
      name: category.name,
      slug: category.slug,
      incidents: render_incidents(category.incidents)
    }
  end

  defp render_incidents(incidents) do
    for(
      incident <- incidents,
      do: %{
        id: incident.id,
        name: incident.name,
        status: incident.status,
        description: incident.description
      }
    )
  end
end
