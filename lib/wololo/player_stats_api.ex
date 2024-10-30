defmodule Wololo.PlayerStatsAPI do
  require Logger

  @base_url Application.compile_env(:wololo, :api_base_url)

  def fetch_player_stats(profile_id) do
    endpoint = "#{@base_url}/players/#{profile_id}?full_history=true"

    request = Finch.build(:get, endpoint)

    case Finch.request(request, Wololo.Finch) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        # Logger.info("Received countries body: #{inspect(Jason.decode!(body))}")
        {:ok, process_player_stats(body)}

      {:ok, %Finch.Response{status: status_code}} ->
        {:error, "Request failed with status code: #{status_code}"}

      {:error, %Finch.Error{reason: reason}} ->
        {:error, "Request failed: #{reason}"}
    end
  end

  def process_player_stats(body) do
    stats =
      body
      |> Jason.decode!()
      |> get_in(["modes", "rm_solo"])

    rating_history = Map.get(stats, "rating_history", [])
    total_count = Enum.count(rating_history)

    %{
      max_rating: Map.get(stats, "max_rating", "N/A"),
      max_rating_7d: Map.get(stats, "max_rating_7d", "N/A"),
      max_rating_1m: Map.get(stats, "max_rating_1m", "N/A"),
      average_rating:
        if(total_count > 0,
          do: calculate_average_rating(rating_history, total_count),
          else: "N/A"
        ),
      total_count: total_count
    }
  end

  def calculate_average_rating(rating_history, total_count) do
    round(
      Enum.reduce(rating_history, 0, fn {_, %{"rating" => rating}}, acc -> acc + rating end) /
        total_count
    )
  end
end
