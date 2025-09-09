defmodule HeadsUp.Responses do
  @moduledoc """
  The Responses context.
  """

  import Ecto.Query, warn: false
  alias HeadsUp.Repo

  alias HeadsUp.Responses.Response
  alias HeadsUp.Incidents

  @doc """
  Returns the list of responses.

  ## Examples

      iex> list_responses()
      [%Response{}, ...]

  """
  def list_responses do
    Response
    |> preload([:incident, :user])
    |> Repo.all()
  end

  @doc """
  Gets a single response.

  Raises `Ecto.NoResultsError` if the Response does not exist.

  ## Examples

      iex> get_response!(123)
      %Response{}

      iex> get_response!(456)
      ** (Ecto.NoResultsError)

  """
  def get_response!(id), do: Repo.get!(Response, id) |> Repo.preload([:incident, :user])

  @doc """
  Creates a response.

  ## Examples

      iex> create_response(incident, user, %{field: value})
      {:ok, %Response{}}

      iex> create_response(incident, user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_response(incident, user, attrs) do
    %Response{incident: incident, user: user}
    |> Response.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:error, _} = error ->
        error

      {:ok, response} ->
        Incidents.broadcast(incident.id, {:new_response, response})
        {:ok, response}
    end
  end

  @doc """
  Updates a response.

  ## Examples

      iex> update_response(response, %{field: new_value})
      {:ok, %Response{}}

      iex> update_response(response, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_response(%Response{} = response, attrs) do
    response
    |> Response.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a response.

  ## Examples

      iex> delete_response(response)
      {:ok, %Response{}}

      iex> delete_response(response)
      {:error, %Ecto.Changeset{}}

  """
  def delete_response(%Response{} = response) do
    Repo.delete(response)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking response changes.

  ## Examples

      iex> change_response(response)
      %Ecto.Changeset{data: %Response{}}

  """
  def change_response(%Response{} = response, attrs \\ %{}) do
    Response.changeset(response, attrs)
  end
end
