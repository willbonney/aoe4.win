defmodule WololoWeb.CivsByMapController do
  use WololoWeb, :controller
  alias Wololo.CivsByMapAPI
  require Logger

  def index(conn, _params) do
    Logger.info("CivsByMapController.index called at #{DateTime.utc_now()}")

    case CivsByMapAPI.fetch_civs_by_map() do
      {:ok, raw_data} ->
        Logger.info("Successfully fetched civs_by_map data")
        transformed_data = CivsByMapAPI.transform_data(raw_data)
        render(conn, :index, maps: transformed_data)

      {:error, reason} ->
        Logger.error("Failed to fetch civs_by_map data: #{inspect(reason)}")

        conn
        |> put_flash(:error, "Failed to fetch Civs By Map: #{reason}")
        |> redirect(to: ~p"/")
    end
  end
end
