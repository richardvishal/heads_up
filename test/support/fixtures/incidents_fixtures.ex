defmodule HeadsUp.IncidentsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `HeadsUp.Incidents` context.
  """

  import HeadsUp.CategoriesFixtures

  @doc """
  Generate a unique incident name.
  """
  def unique_incident_name, do: "some incident#{System.unique_integer([:positive])}"

  @doc """
  Generate a unique priority (cycled).
  """
  def unique_incident_priority, do: rem(System.unique_integer([:positive]), 3) + 1

  @doc """
  Generate an incident.
  """
  def incident_fixture(attrs \\ %{}) do
    category = Map.get(attrs, :category, category_fixture())

    {:ok, incident} =
      attrs
      |> Enum.into(%{
        name: unique_incident_name(),
        status: :pending,
        priority: unique_incident_priority(),
        category_id: category.id,
        description: "some description"
      })
      |> HeadsUp.Admin.create_incident()

    incident
  end
end
