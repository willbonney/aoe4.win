defmodule WololoWeb.OpponentsByCountryLive do
  use WololoWeb, :live_view
  alias Wololo.OpponentsByCountryAPI
  alias WololoWeb.SearchComponent
  import WololoWeb.Components.Spinner

  @countries %{}

  @impl true
  def mount(params, session, socket) do
    {:ok, data} = OpponentsByCountryAPI.fetch_last_50_player_games()
    socket = assign(socket, countries: data, loading: false, error: nil)

    {:ok, socket |> push_event("update-player", %{byCountry: data})}
  end

  @impl true
  def handle_event("select-player", %{"player" => player}, socket) do
    countries = socket.assigns.countries
    IO.inspect(countries, label: "countries")

    {:noreply, socket |> push_event("update-player", %{byCountry: countries})}
  end
end
