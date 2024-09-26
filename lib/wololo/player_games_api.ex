defmodule Wololo.PlayerGamesAPI do
  require Logger

  @base_url Application.compile_env(:wololo, :api_base_url)

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
end
