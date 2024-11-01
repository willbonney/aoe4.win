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
    "zhu_xis_legacy"
  ]

  def fetch_civs_by_map(league \\ nil) do
    Logger.info("Fetching civs_by_map data for #{league}")
    endpoint = "#{@base_url}/stats/rm_solo/maps?include_civs=true"

    url =
      if league do
        "#{endpoint}&rank_level=#{URI.encode_www_form(league)}"
      else
        endpoint
      end

    IO.inspect(url, label: "url")

    request = Finch.build(:get, url)

    case Finch.request(request, Wololo.Finch) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        {:ok, Jason.decode!(body)}

      {:ok, %Finch.Response{status: status}} ->
        Logger.error("API request failed with status: #{status}")
        {:error, "Request failed with status code: #{status}"}

      {:error, reason} ->
        Logger.error("API request error: #{inspect(reason)}")
        {:error, "Request failed: #{inspect(reason)}"}
    end
  end

  def transform_data(raw_data) do
    Enum.map(raw_data["data"], fn map_data ->
      civ_data = map_data["civilizations"]

      civ_win_rates =
        @list_of_civs
        |> Enum.map(fn civ ->
          win_rate = get_in(civ_data, [civ, "win_rate"])
          {String.to_atom(civ), format_win_rate(win_rate)}
        end)
        |> Enum.into(%{})

      Map.merge(%{name: map_data["map"]}, civ_win_rates)
    end)
  end

  defp format_win_rate(nil), do: "N/A"
  defp format_win_rate(win_rate) when win_rate == 0 or win_rate == 100, do: "N/A"

  defp format_win_rate(win_rate) do
    :io_lib.format("~.2f%", [win_rate])
    |> to_string()
  end
end
