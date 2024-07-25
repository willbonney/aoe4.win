defmodule WololoWeb.PlayerController do
  use WololoWeb, :controller
  alias Wololo.PlayerAPI

  def index(conn, _params) do
    render(conn, :index)
  end

  def show(conn, %{"id" => id}) do
    case PlayerAPI.fetch_player(id) do
      {:ok, player} ->
        render(conn, :show, player: player)

      {:error, reason} ->
        conn
        |> put_flash(:error, "Failed to fetch player: #{reason}")
        |> redirect(to: ~p"/")
    end
  end
end
