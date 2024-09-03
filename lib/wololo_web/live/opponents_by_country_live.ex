defmodule WololoWeb.OpponentsByCountryLive do
  use WololoWeb, :live_view
  alias Wololo.OpponentsByCountryAPI
  alias WololoWeb.SearchComponent
  import WololoWeb.Components.Spinner

  @impl true
  def mount(params, session, socket) do
    socket = assign(socket, countries: [], loading: true, show: true, error: nil)
    {:ok, socket}
  end

  @impl true
  def handle_event("select-player", %{"id" => profile_id}, socket) do
    IO.inspect(profile_id, label: "profile_id")

    {:ok, data} = OpponentsByCountryAPI.fetch_last_50_player_games(profile_id)

    {:noreply,
     socket
     |> assign(countries: data, loading: false, show: false, error: nil)
     |> push_event("update-player", %{byCountry: data})}
  end
end
