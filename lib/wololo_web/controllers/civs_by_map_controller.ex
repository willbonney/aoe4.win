defmodule WololoWeb.CivsByMapController do
  use WololoWeb, :controller
  alias Wololo.CivsByMapAPI

  def index(conn, _params) do
    render(conn, :index)
  end

  def show(conn, _) do
    case CivsByMapAPI.fetch_civs_by_map() do
      {:ok, _} ->
        render(conn, :show)

      {:error, reason} ->
        conn
        |> put_flash(:error, "Failed to fetch Civs By Map: #{reason}")
        |> redirect(to: ~p"/")
    end
  end
end
