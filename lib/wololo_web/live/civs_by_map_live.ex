defmodule WololoWeb.CivsByMapLive do
  use WololoWeb, :live_view
  alias Wololo.CivsByMapAPI
  require Logger

  @impl true
  def mount(_params, _session, socket) do
    civs = [
      %{key: :name, label: "Map", image: "map"},
      %{key: :abbasid_dynasty, label: "Abbasid Dynasty", image: "abbasid_dynasty"},
      %{key: :chinese, label: "Chinese", image: "chinese"},
      %{key: :delhi_sultanate, label: "Delhi Sultanate", image: "delhi_sultanate"},
      %{key: :english, label: "English", image: "english"},
      %{key: :french, label: "French", image: "french"},
      %{key: :holy_roman_empire, label: "Holy Roman Empire", image: "holy_roman_empire"},
      %{key: :mongols, label: "Mongols", image: "mongols"},
      %{key: :rus, label: "Rus", image: "rus"},
      %{key: :ottomans, label: "Ottomans", image: "ottomans"},
      %{key: :malians, label: "Malians", image: "malians"},
      %{key: :byzantines, label: "Byzantines", image: "byzantines"},
      %{key: :japanese, label: "Japanese", image: "japanese"},
      %{key: :ayyubids, label: "Ayyubids", image: "ayyubids"},
      %{key: :jeanne_darc, label: "Jeanne d'Arc", image: "jeanne_darc"},
      %{key: :order_of_the_dragon, label: "Order of the Dragon", image: "order_of_the_dragon"},
      %{key: :zhu_xis_legacy, label: "Zhu Xi's Legacy", image: "zhu_xis_legacy"}
    ]

    case CivsByMapAPI.fetch_civs_by_map() do
      {:ok, raw_data} ->
        Logger.info("Successfully fetched civs_by_map data")
        transformed_data = CivsByMapAPI.transform_data(raw_data)
        {:ok, assign(socket, maps: transformed_data, civs: civs)}

      {:error, reason} ->
        Logger.error("Failed to fetch civs_by_map data: #{inspect(reason)}")

        {:ok,
         assign(socket, maps: [], civs: civs, error: "Failed to fetch Civs By Map: #{reason}")}
    end
  end

  @impl true
  def handle_event("click_btn", _params, socket) do
    IO.inspect("Button clicked", label: "click")
    {:noreply, socket}
  end

  def civ_header(assigns) do
    ~H"""
    <div class="flex items-center flex-col">
      <img src={"/images/#{@civ}.png"} alt={@label} class="w-10 h-6 mr-2" />
      <span><%= @label %></span>
    </div>
    """
  end

  def bg_color(percentage) when is_binary(percentage) do
    case Float.parse(percentage) do
      {value, "%"} -> bg_color(value)
      # Default color for invalid input
      _ -> "bg-gray-100"
    end
  end

  def bg_color(percentage) when is_number(percentage) do
    cond do
      percentage < 45 -> "bg-red-500"
      percentage < 47 -> "bg-red-400"
      percentage < 49 -> "bg-red-300"
      percentage < 50 -> "bg-red-200"
      percentage == 50 -> "bg-gray-200"
      percentage < 51 -> "bg-green-200"
      percentage < 53 -> "bg-green-300"
      percentage < 55 -> "bg-green-400"
      true -> "bg-green-500"
    end
  end

  # Default color for any other input
  def bg_color(_), do: "bg-gray-100"
end
