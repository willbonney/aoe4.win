defmodule Wololo.CivsByMapAPI do
  require Logger

  @base_url Application.compile_env(:wololo, :api_base_url)

  @list_of_civs [
    "abbasid_dynasty",
    "chinese",
    "delhi_sultanate",
    "english",
    "french",
    "holy_roman_empire",
    "mongols",
    "rus",
    "ottomans",
    "malians",
    "byzantines",
    "japanese",
    "ayyubids",
    "jeanne_darc",
    "order_of_the_dragon",
    "zhu_xis_legacy",
    "knights_templar",
    "house_of_lancaster"
  ]

  def fetch_civs_by_map(league \\ nil) do
    Logger.info("Fetching civs_by_map data for #{league}")
    cache_key = "civs_by_map_#{league || "all"}"

    case Cachex.get(:wololo_cache, cache_key) do
      {:ok, nil} ->
        # Cache miss, make the API call
        result = make_api_request(build_url(league))

        if match?({:ok, _}, result),
          do: Cachex.put(:wololo_cache, cache_key, result, ttl: :timer.hours(24))

        result

      {:ok, cached_result} ->
        cached_result

      {:error, _} ->
        # Error reading from cache, fall back to API call
        make_api_request(build_url(league))
    end
  end

  defp build_url(league) do
    endpoint = "#{@base_url}/stats/rm_solo/maps?include_civs=true"

    if league do
      "#{endpoint}&rank_level=#{URI.encode_www_form(league)}"
    else
      endpoint
    end
  end

  defp make_api_request(url) do
    IO.inspect(url, label: "url")
    request = Finch.build(:get, url)

    case Finch.request(request, Wololo.Finch) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, decoded} ->
            {:ok, decoded}

          {:error, reason} ->
            Logger.error("Failed to decode JSON response: #{inspect(reason)}")
            {:error, "Invalid JSON response"}
        end

      {:ok, %Finch.Response{status: status}} ->
        Logger.error("API request failed with status #{status}")
        {:error, "civs_by_map make_api_request failed with status code: #{status}"}

      {:error, reason} ->
        Logger.error("API request failed: #{inspect(reason)}")
        {:error, "civs_by_map make_api_request failed: #{inspect(reason)}"}
    end
  end

  def transform_data(raw_data) when is_map(raw_data) do
    case raw_data do
      %{"data" => data} when is_list(data) ->
        Enum.map(data, fn map_data ->
          case map_data do
            %{"civilizations" => civ_data, "map" => map_name} when is_map(civ_data) ->
              civ_win_rates =
                @list_of_civs
                |> Enum.map(fn civ ->
                  win_rate = get_in(civ_data, [civ, "win_rate"])
                  {String.to_atom(civ), format_win_rate(win_rate)}
                end)
                |> Enum.into(%{})

              Map.merge(%{name: map_name}, civ_win_rates)

            _ ->
              Logger.error("Invalid map data structure: #{inspect(map_data)}")
              %{name: "Unknown", error: "Invalid data structure"}
          end
        end)

      _ ->
        Logger.error("Invalid raw_data structure: #{inspect(raw_data)}")
        []
    end
  end

  defp format_win_rate(nil), do: "N/A"

  defp format_win_rate(win_rate) when is_number(win_rate) and win_rate >= 0 and win_rate <= 100 do
    # / 1 to convert to float
    :io_lib.format("~.2f%", [win_rate / 1])
    |> to_string()
  end

  defp format_win_rate(win_rate) when is_number(win_rate) do
    Logger.error("Win rate out of range: #{inspect(win_rate)}")
    "N/A"
  end

  defp format_win_rate(_), do: "N/A"
end
