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

  def get_players_games_statistics(profile_id) do
    endpoint = "#{@base_url}/players/#{profile_id}/games?leaderboard=rm_solo"
    IO.inspect(endpoint, label: "endpoint")

    request = Finch.build(:get, endpoint)

    case Finch.request(request, Wololo.Finch) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        # Logger.info("Received countries body: #{inspect(Jason.decode!(body))}")
        {:ok, process_games(body, profile_id)}

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
        )

      acc
    end)

    # |> tap(&IO.inspect(&1, label: "Final processed player data"))
  end
end

#   def process_games(body, profile_id) do
#     games = body |> Jason.decode!() |> Map.get("games")

#     {countries, ^moving_averages} =
#       games
#       |> Enum.reduce({%{}, {[], []}}, fn game, {countries, {moving_averages, ratings}} ->
#         {player_team, opponent_team} =
#           Enum.split_with(game["teams"], fn [team | _] -> team["profile_id"] == profile_id end)

#         [[opponent], _] = opponent_team

#         opponent_country = opponent["player"]["country"]

#         countries =
#           if Map.get(countries, opponent_country) == nil do
#             Map.put(countries, opponent_country, 1)
#           else
#             Map.update(countries, opponent_country, 1, &(&1 + 1))
#           end

#         [_, [player]] = player_team

#         player_rating = player["player"]["rating"]
#         ratings = [rating | ratings]
#         if length(ratings) > 10, do: ratings = Enum.take(ratings, 10)

#         if length(ratings) == 10 do
#           average = Enum.sum(ratings) / 10
#           moving_averages = [{game["updated_at"], average} | moving_averages]
#         end

#         {countries, {moving_averages, ratings}}
#       end)

#     moving_averages = moving_averages |> Enum.reverse()

#     %{countries: countries, moving_averages: moving_averages}
#     |> tap(&IO.inspect(&1, label: "Final processed player data"))
#   end
# end
