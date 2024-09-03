defmodule Wololo.OpponentsByCountryAPI do
  require Logger

  @base_url Application.compile_env(:wololo, :api_base_url)
  @expected_fields ~w(avatars country modes)a

  def fetch_last_50_player_games(profile_id) do
    endpoint = "#{@base_url}/players/#{profile_id}/games?leaderboard=rm_solo"

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
    |> Enum.reduce(%{}, fn game, acc ->
      {_, opponent_team} =
        Enum.split_with(game["teams"], fn [team | _] -> team["profile_id"] == profile_id end)

      [[opponent], _] = opponent_team

      opponent_country = opponent["player"]["country"]

      if(Map.get(acc, opponent_country) == nil) do
        Map.put(acc, opponent_country, 1)
      else
        Map.update(acc, opponent_country, 1, &(&1 + 1))
      end
    end)
    |> tap(&IO.inspect(&1, label: "Final processed player data"))
  end
end
