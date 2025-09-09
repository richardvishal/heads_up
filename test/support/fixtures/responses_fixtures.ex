defmodule HeadsUp.ResponsesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `HeadsUp.Responses` context.
  """

  alias HeadsUp.{Responses, IncidentsFixtures, AccountsFixtures}

  @doc """
  Generate a response.
  """
  def response_fixture(attrs \\ %{}) do
    incident = Map.get(attrs, :incident, IncidentsFixtures.incident_fixture())
    user = Map.get(attrs, :user, AccountsFixtures.user_fixture())

    attrs =
      attrs
      |> Enum.into(%{
        note: "some note",
        status: :enroute
      })

    {:ok, response} = Responses.create_response(incident, user, attrs)

    response
  end
end
