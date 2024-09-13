defmodule Wololo.OpponentsByCountryAPI do
  require Logger

  @base_url Application.compile_env(:wololo, :api_base_url)
  @expected_fields ~w(avatars country modes)a

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
    |> Enum.reduce(%{countries: %{}, ratings: []}, fn game, acc ->
      {player_team, opponent_team} =
        Enum.split_with(game["teams"], fn [team | _] ->
          to_string(team["player"]["profile_id"]) == profile_id
        end)

      # IO.inspect(opponent_team, label: "opponent_team")
      # IO.inspect(player_team, label: "player_team")

      [[opponent]] = opponent_team
      [[player]] = player_team

      # IO.inspect(opponent, label: "opponent")
      # IO.inspect(player, label: "player")

      opponent_country = opponent["player"]["country"]

      # IO.inspect(opponent_country, label: "opponent_country")
      # IO.inspect(acc[:countries][opponent_country], label: " acc[:countries][opponent_country]")

      acc =
        if acc[:countries][opponent_country] == nil do
          update_in(acc, [:countries], &Map.put(&1, opponent_country, 1))
        else
          update_in(
            acc,
            [:countries],
            &Map.update(&1, opponent_country, 1, fn count -> count + 1 end)
          )
        end

      # IO.inspect(player_team, label: "player_team")

      player_rating = player["player"]["rating"]
      updated_at = game["updated_at"]
      # IO.inspect(acc[:ratings], label: "acc[:ratings]")
      # IO.inspect(length(acc[:ratings]), label: "length(acc[:ratings])")

      acc =
        Map.update(
          acc,
          :ratings,
          [
            %{player_rating: player_rating, updated_at: updated_at, moving_average_10d: 0}
          ],
          fn ratings ->
            moving_average_10d =
              if length(ratings) <= 10 do
                0
              else
                current_index = length(ratings)
                IO.inspect(current_index, label: "current_index")
                IO.inspect(ratings, label: "ratings")

                # if current_index >= 10 do
                # start_index = max(current_index - 10, 0)
                first_10_ratings =
                  Enum.slice(ratings, 0, 10)

                # else
                #   []
                # end

                Enum.reduce(first_10_ratings, 0, fn %{player_rating: rating}, acc ->
                  acc + rating
                end) / 10
              end

            IO.inspect(moving_average_10d, label: "moving_average_10d")

            new_ratings = [
              %{
                player_rating: player_rating,
                updated_at: updated_at,
                moving_average_10d: moving_average_10d
              }
              | ratings
            ]

            Enum.reverse(new_ratings)
          end
        )

      # IO.inspect(acc, label: "acc")

      # IO.inspect(ratings, label: "ratings")

      acc

      # IO.inspect(ratings, label: "ratings")

      # case length(ratings) do

      #   10 -> Map.put(acc, :ratings, ratings)
      # end

      # if length(ratings) > 10, do: ratings = Enum.take(ratings, 10)

      # if length(ratings) == 10 do
      #   average = Enum.sum(ratings) / 10

      #   Map.put(acc, :moving_averages, [
      #     {game["updated_at"], average} | Map.get(acc, :moving_averages)
      #   ])

      #   Map.put(acc, :ratings, ratings)
      # end
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
