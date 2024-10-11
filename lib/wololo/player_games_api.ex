defmodule Wololo.PlayerGamesAPI do
  require Logger

  @base_url Application.compile_env(:wololo, :api_base_url)
  @game_length_buckets %{
    _lt_600: 0,
    _600_to_899: 0,
    _900_to_1199: 0,
    _1200_to_1499: 0,
    _1500_to_1799: 0,
    _1800_to_2099: 0,
    _gt_2100: 0
  }

  defp get_moving_average(ratings, games_count) do
    current_index = length(ratings)
    games_count_minus_one = games_count - 1

    if length(ratings) <= games_count do
      nil
    else
      prev_x_ratings =
        if current_index >= games_count_minus_one do
          Enum.take(ratings, -games_count)
        else
          []
        end

      Enum.reduce(prev_x_ratings, 0, fn %{player_rating: rating}, acc ->
        acc + rating
      end) / games_count
    end
  end

  def get_player_wr_by_game_length(profile_id) do
    case get_players_games_statistics(profile_id, false) do
      {:ok, game_stats} ->
        games = Jason.decode!(game_stats)["games"]

        games_by_length = count_games_by_length(games)
        IO.inspect(games_by_length, label: ">>>>>>>>>>>>>>>>>>>games_by_length")

        wins_by_game_length = count_wins_by_game_length(games, profile_id)

        IO.inspect(wins_by_game_length, label: ">>>>>>>>>>>>>>>>>>>wins_by_game_length")

        wrs_by_game_length =
          Enum.into(@game_length_buckets, %{}, fn {bucket, _} ->
            wins = Map.get(wins_by_game_length, bucket, 0)
            total_games = Map.get(games_by_length, bucket, 0)
            win_rate = if total_games > 0, do: wins / total_games * 100, else: 0
            {bucket, win_rate}
          end)

        IO.inspect(wrs_by_game_length, label: "wrs_by_game_length")
        {:ok, wrs_by_game_length}

      {:error, reason} ->
        Logger.error("Failed to get player games statistics: #{reason}")
        {:error, "Failed to retrieve player data"}
    end
  end

  def get_players_games_statistics(profile_id, should_process \\ true) do
    endpoint = "#{@base_url}/players/#{profile_id}/games?leaderboard=rm_solo"

    request = Finch.build(:get, endpoint)

    case Finch.request(request, Wololo.Finch) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        # Logger.info("Received countries body: #{inspect(Jason.decode!(body))}")
        data =
          if should_process do
            process_games(body, profile_id)
          else
            body
          end

        {:ok, data}

      {:ok, %Finch.Response{status: status_code}} ->
        {:error, "Request failed with status code: #{status_code}"}

      {:error, %Finch.Error{reason: reason}} ->
        {:error, "Request failed: #{reason}"}
    end
  end

  def process_games(body, profile_id) do
    body
    |> Jason.decode!()
    |> Map.get("games")
    |> Enum.reverse()
    |> Enum.reduce(%{countries: %{}, ratings: []}, fn game, acc ->
      {player_team, opponent_team} =
        Enum.split_with(game["teams"], fn [team | _] ->
          to_string(team["player"]["profile_id"]) == profile_id
        end)

      [[opponent]] = opponent_team
      [[player]] = player_team
      opponent_country = opponent["player"]["country"]

      acc =
        if acc[:countries][opponent_country] == nil do
          # 2% because we have 50 games
          update_in(acc, [:countries], &Map.put(&1, opponent_country, 2))
        else
          update_in(
            acc,
            [:countries],
            &Map.update(&1, opponent_country, 2, fn count -> count + 2 end)
          )
        end

      player_rating = player["player"]["rating"]
      updated_at = game["updated_at"]

      acc =
        Map.update(
          acc,
          :ratings,
          [
            %{
              player_rating: player_rating,
              updated_at: updated_at,
              moving_average_5g: 0,
              moving_average_10g: 0,
              moving_average_20g: 0
            }
          ],
          fn ratings ->
            if player_rating == nil do
              ratings
            else
              ratings ++
                [
                  %{
                    player_rating: player_rating,
                    updated_at: updated_at,
                    moving_average_5g: get_moving_average(ratings, 5),
                    moving_average_10g: get_moving_average(ratings, 10),
                    moving_average_20g: get_moving_average(ratings, 20)
                  }
                ]
            end
          end
        )

      acc
    end)
  end

  defp count_games_by_length(games) do
    Enum.reduce(games, @game_length_buckets, fn game, acc ->
      bucket = get_duration_bucket(game["duration"])
      Map.update(acc, bucket, 1, &(&1 + 1))
    end)
  end

  defp count_wins_by_game_length(games, profile_id) do
    Enum.reduce(games, @game_length_buckets, fn game, acc ->
      {player_team, _} =
        Enum.split_with(game["teams"], fn [team | _] ->
          to_string(team["player"]["profile_id"]) == profile_id
        end)

      [[player]] = player_team
      won = if player["player"]["result"] == "win", do: 1, else: 0
      bucket = get_duration_bucket(game["duration"])

      Map.update(acc, bucket, won, &(&1 + won))
    end)
  end

  defp get_duration_bucket(duration) do
    cond do
      duration < 600 -> :_lt_600
      duration < 900 -> :_600_to_899
      duration < 1200 -> :_900_to_1199
      duration < 1500 -> :_1200_to_1499
      duration < 1800 -> :_1500_to_1799
      duration < 2100 -> :_1800_to_2099
      true -> :_gt_2100
    end
  end
end
