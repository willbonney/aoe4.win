defmodule Wololo.SearchPlayerAPI do
  require Logger

  @base_url Application.compile_env(:wololo, :api_base_url)

  def fetch_player(name) do
    encoded_name = URI.encode_www_form(name)
    endpoint = "#{@base_url}/players/autocomplete?leaderboard=rm_solo&query=#{encoded_name}"

    case Wololo.HTTPClient.get_with_retry(endpoint) do
      {:ok, body} ->
        {:ok, Jason.decode!(body)}

      {:error, reason} ->
        {:error, "search_player_api fetch_player failed: #{reason}"}
    end
  end
end
