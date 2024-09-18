defmodule WololoWeb.OpponentsByCountryLive do
  use WololoWeb, :live_component
  alias Wololo.PlayerGamesAPI
  import WololoWeb.Components.Spinner

  def mount(socket) do
    {:ok, socket |> assign(profile_id: nil, countries: [], loading: true, error: nil)}
  end

  def update(assigns, socket) do
    case PlayerGamesAPI.get_players_games_statistics(assigns[:profile_id]) do
      {:ok, data} ->
        {
          :ok,
          socket
          |> assign(countries: data[:countries], loading: false, error: nil)
          |> push_event("update-player", %{byCountry: data[:countries]})
        }

      {:error, reason} ->
        {
          :ok,
          socket
          |> assign(countries: [], loading: false, error: reason)
        }
    end
  end
end
