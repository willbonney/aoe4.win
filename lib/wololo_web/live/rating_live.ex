defmodule WololoWeb.RatingLive do
  alias Wololo.PlayerGamesAPI
  use WololoWeb, :live_component
  import WololoWeb.Components.Spinner
  alias Wololo.PlayerStatsAPI
  import Wololo.Utils, only: [rating_to_color_map: 1]
  alias Phoenix.LiveView.AsyncResult

  def mount(socket) do
    {:ok,
     socket
     |> assign(:stats, %AsyncResult{})
     |> assign(:error, nil)}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign(:stats, AsyncResult.loading())
      |> start_async(:get_stats, fn -> fetch_stats(assigns[:profile_id]) end)

    {:ok, socket}
  end

  @impl true
  def handle_async(:get_stats, {:ok, {:error, reason}}, socket) do
    {:noreply,
     assign(socket,
       stats: %Phoenix.LiveView.AsyncResult{
         ok?: false,
         loading: false,
         failed: reason,
         result: nil
       }
     )}
  end

  def handle_async(:get_stats, {:ok, result}, socket) do
    socket =
      socket
      |> assign(:stats, AsyncResult.ok(%AsyncResult{}, result))
      |> push_event("update-player", %{movingAverages: result.moving_averages})

    {:noreply, socket}
  end

  def handle_async(:get_stats, {:error, reason}, socket) do
    socket =
      socket
      |> assign(:stats, AsyncResult.failed(%AsyncResult{}, reason))
      |> assign(:error, reason)

    {:noreply, socket}
  end

  def fetch_stats(profile_id) do
    with {:ok, opponents_data} <- PlayerGamesAPI.get_players_games_statistics(profile_id),
         {:ok, player_stats} <- PlayerStatsAPI.fetch_player_stats(profile_id) do
      # Return just the map without wrapping it in a tuple
      %{
        moving_averages: opponents_data[:ratings],
        max_rating: player_stats[:max_rating],
        max_rating_7d: player_stats[:max_rating_7d],
        max_rating_1m: player_stats[:max_rating_1m],
        average_rating: player_stats[:average_rating],
        total_count: player_stats[:total_count]
      }
    else
      {:error, reason} -> {:error, reason}
    end
  end
end
