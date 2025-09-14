defmodule HeadsUp.Incidents.IncidentTest do
  use HeadsUp.DataCase

  alias HeadsUp.Incidents.Incident

  describe "changeset/2" do
    test "adds an error for invalid priority" do
      changeset_low = Incident.changeset(%Incident{}, %{priority: 0})
      assert %{priority: ["Priority should be between 1 and 3"]} = errors_on(changeset_low)

      changeset_high = Incident.changeset(%Incident{}, %{priority: 4})
      assert %{priority: ["Priority should be between 1 and 3"]} = errors_on(changeset_high)
    end

    test "does not add an error for valid priority" do
      for priority <- 1..3 do
        refute errors_on(Incident.changeset(%Incident{}, %{priority: priority}))[:priority]
      end
    end
  end
end
