defmodule Wololo.SearchPlayerAPI do
  require Logger

  @base_url Application.compile_env(:wololo, :api_base_url)

  def fetch_player(name) do
    encoded_name = URI.encode_www_form(name)
    endpoint = "#{@base_url}/players/autocomplete?leaderboard=rm_solo&query=#{encoded_name}"

    request = Finch.build(:get, endpoint)

    case Finch.request(request, Wololo.Finch) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        {:ok, Jason.decode!(body)}

      {:ok, %Finch.Response{status: status_code}} ->
        {:error, "search_player_api fetch_player failed with status code: #{status_code}"}

      {:error, %Finch.Error{reason: reason}} ->
        {:error, "search_player_api fetch_player failed: #{reason}"}

      {:error, %Mint.TransportError{reason: reason}} ->
        Logger.error("search_player_api fetch_player transport error: #{reason}")
        {:error, "search_player_api fetch_player failed: connection timeout"}

      {:error, error} ->
        Logger.error("search_player_api fetch_player unexpected error: #{inspect(error)}")
        {:error, "search_player_api fetch_player failed: unexpected error"}
    end
  end
end
