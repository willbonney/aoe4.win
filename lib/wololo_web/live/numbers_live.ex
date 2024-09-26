defmodule WololoWeb.NumbersLive do
  alias Wololo.PlayerGamesAPI
  use WololoWeb, :live_component
  import WololoWeb.Components.Spinner
  alias Wololo.PlayerStatsAPI

  def mount(socket) do
    {:ok, socket |> assign(stats: nil, loading: true, error: nil)}
  end

  def update(assigns, socket) do
    assign(socket, loading: true)

    profile_id = assigns[:profile_id]

    {opponents_result, player_stats_result} =
      {PlayerGamesAPI.get_players_games_statistics(profile_id),
       PlayerStatsAPI.fetch_player_stats(profile_id)}

    socket =
      case opponents_result do
        {:ok, data} ->
          socket
          |> assign(moving_averages: data[:ratings], loading: false, error: nil)
          |> push_event("update-player", %{movingAverages: data[:ratings]})

        {:error, reason} ->
          socket
          |> assign(moving_averages: [], loading: false, error: reason)
      end

    socket =
      case player_stats_result do
        {:ok, data} ->
          socket
          |> assign(stats: data, loading: false, error: nil)

        {:error, reason} ->
          socket
          |> assign(stats: %{}, loading: false, error: reason)
      end

    {:ok, socket}
  end
end
