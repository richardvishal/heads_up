defmodule HeadsUp.Repo.Migrations.AddHeroicResponseIdToIncidents do
  use Ecto.Migration

  def change do
    alter table(:incidents) do
      add :heroic_response_id, references(:responses)
    end

    create index(:incidents, [:heroic_response_id])
  end
end
