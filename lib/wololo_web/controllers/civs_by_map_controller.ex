defmodule WololoWeb.CivsByMapController do
  use WololoWeb, :controller
  alias Wololo.CivsByMapAPI
  require Logger

  def index(conn, _params) do
    Logger.info("CivsByMapController.index called at #{DateTime.utc_now()}")

    case CivsByMapAPI.fetch_civs_by_map() do
      {:ok, civs_by_map_data} ->
        Logger.info("Successfully fetched civs_by_map data")
        render(conn, :index, civs_by_map_data: civs_by_map_data)

      {:error, reason} ->
        Logger.error("Failed to fetch civs_by_map data: #{inspect(reason)}")

        conn
        |> put_flash(:error, "Failed to fetch Civs By Map: #{reason}")
        |> redirect(to: ~p"/")
    end
  end
end
