defmodule Wololo.PlayerStatsAPI do
  require Logger

  @base_url Application.compile_env(:wololo, :api_base_url)

  def fetch_player_data(profile_id, with_stats \\ false) do
    endpoint = "#{@base_url}/players/#{profile_id}?full_history=true"

    request = Finch.build(:get, endpoint)

    case Finch.request(request, Wololo.Finch) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        {:ok, if(with_stats, do: process_player_stats(body), else: Jason.decode!(body))}

      {:ok, %Finch.Response{status: status_code}} ->
        {:error, "fetch_player_data failed with status code: #{status_code}"}

      {:error, %Finch.Error{reason: reason}} ->
        {:error, "fetch_player_data failed: #{reason}"}
    end
  end

  def process_player_stats(body) do
    stats =
      body
      |> Jason.decode!()
      |> get_in(["modes", "rm_solo"])

    rating_history = Map.get(stats, "rating_history", [])
    total_count = Enum.count(rating_history)
    total_seasons = Enum.count(stats["previous_seasons"]) + 1

    rank_history =
      Enum.map(stats["previous_seasons"], fn season ->
        %{
          rank: season["rank"],
          season: season["season"]
        }
      end)

    %{
      max_rating: Map.get(stats, "max_rating", "N/A"),
      max_rating_7d: Map.get(stats, "max_rating_7d", "N/A"),
      max_rating_1m: Map.get(stats, "max_rating_1m", "N/A"),
      average_rating:
        if(total_count > 0,
          do: calculate_average_rating(rating_history, total_count),
          else: "N/A"
        ),
      total_count: total_count,
      rank_history: rank_history,
      total_seasons: total_seasons,
      average_rank: calculate_average_rank(rank_history, total_seasons),
      min_rank: Enum.min_by(rank_history, fn %{rank: rank} -> rank end).rank,
      max_rank: Enum.max_by(rank_history, fn %{rank: rank} -> rank end).rank
    }
  end

  def calculate_average_rating(rating_history, total_count) do
    round(
      Enum.reduce(rating_history, 0, fn {_, %{"rating" => rating}}, acc -> acc + rating end) /
        total_count
    )
  end

  def calculate_average_rank(rank_history, total_count) do
    round(
      Enum.reduce(rank_history, 0, fn {_, %{"rank" => rank}}, acc -> acc + rank end) /
        total_count
    )
  end
end
