defmodule HeadsUp.IncidentsBehaviour do
  @callback urgent_incidents(term()) :: {:ok, %{urgent_incidents: list()}} | {:error, String.t()}
  # add more callbacks from your Incidents context as needed
end
