defmodule Wololo.OpponentsByCountryAPI do
  require Logger

  @base_url Application.compile_env(:wololo, :api_base_url)
  @expected_fields ~w(avatars country modes)a
  @player_id "76561197961443238"

  def fetch_last_50_player_games() do
    endpoint = "#{@base_url}/players/#{@player_id}/games?leaderboard=rm_solo"

    request = Finch.build(:get, endpoint)

    case Finch.request(request, Wololo.Finch) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        # Logger.info("Received countries body: #{inspect(Jason.decode!(body))}")
        {:ok, process_games(body)}

      {:ok, %Finch.Response{status: status_code}} ->
        {:error, "Request failed with status code: #{status_code}"}

      {:error, %Finch.Error{reason: reason}} ->
        {:error, "Request failed: #{reason}"}
    end
  end

  def process_games(body) do
    body
    |> Jason.decode!()
    |> Map.get("data.games")
    |> Enum.reduce(%{}, fn game, acc ->
      {_, opponent_team} =
        Enum.split_with(game["teams"], fn team -> team[0]["profile_id"] == @player_id end)

      opponent_country = opponent_team[0][1]["country"]

      if(Map.get(acc, opponent_country) == nil) do
        Map.put(acc, opponent_country, 1)
      else
        Map.put(acc, opponent_country, Map.get(acc, opponent_country) + 1)
      end

      acc
    end)
    |> Logger.info(label: "Processed player data")
    # |> then(fn decoded -> Map
    #   for game <- @decoded.games,
    #       value = Map.get(decoded, to_string(field)),
    #       value != nil,
    #       into: %{} do
    #     {field, value}
    #   end
    # end)
    |> tap(&IO.inspect(&1, label: "Final processed player data"))
  end
end
