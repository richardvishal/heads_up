defmodule HeadsUp.Incidents.Incident do
  use Ecto.Schema
  import Ecto.Changeset

  schema "incidents" do
    field :name, :string
    field :priority, :integer, default: 1
    field :status, Ecto.Enum, values: [:pending, :resolved, :canceled], default: :pending
    field :description, :string
    field :image_path, :string, default: "/images/placeholder.jpg"

    belongs_to :category, HeadsUp.Categories.Category

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(incident, attrs) do
    incident
    |> cast(attrs, [:name, :description, :priority, :status, :image_path])
    |> validate_required([:name, :description, :priority, :status, :image_path])
    |> validate_length(:description, min: 10)
    |> validate_priority()
  end

  defp validate_priority(%Ecto.Changeset{changes: %{priority: priority}} = changeset)
       when priority > 3 or priority < 1 do
    changeset
    |> add_error(:priority, "Priority should be between 1 and 3")
  end

  defp validate_priority(changeset), do: changeset
end
