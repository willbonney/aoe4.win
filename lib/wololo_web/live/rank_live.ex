defmodule WololoWeb.RankLive do
  alias Wololo.PlayerGamesAPI
  use WololoWeb, :live_component
  import WololoWeb.Components.Spinner
  alias Wololo.PlayerStatsAPI
  import Wololo.Utils, only: [rating_to_color_map: 1]
  alias Phoenix.LiveView.AsyncResult

  @impl true
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
      |> start_async(:get_stats, fn -> fetch_rank(assigns[:profile_id]) end)

    {:ok, socket}
  end

  def handle_async(:get_stats, {:ok, result}, socket) do
    case result do
      {:error, reason} ->
        socket =
          socket
          |> assign(:stats, AsyncResult.failed(%AsyncResult{}, reason))
          |> assign(:error, reason)

        {:noreply, socket}

      stats ->
        socket =
          socket
          |> assign(:stats, AsyncResult.ok(%AsyncResult{}, stats))
          |> push_event("update-player", %{movingAverages: stats.moving_averages})

        {:noreply, socket}
    end
  end

  @impl true
  def handle_async(:get_stats, {status, reason}, socket) when status in [:error, :exit, :ok] do
    socket =
      socket
      |> assign(:stats, AsyncResult.failed(%AsyncResult{}, reason))
      |> assign(:error, reason)

    {:noreply, socket}
  end

  def fetch_rank(profile_id) do
    with {:stats, {:ok, player_stats}} <-
           {:stats, PlayerStatsAPI.fetch_player_data(profile_id, true)} do
      %{
        rank_history: player_stats[:rank_history],
        min_rank: player_stats[:min_rank],
        max_rank: player_stats[:max_rank],
        average_rank: player_stats[:average_rank]
      }
    else
      {:stats, {:error, reason}} ->
        {:error, "Failed to fetch player stats: #{reason}"}
    end
  end
end
