defmodule WololoWeb.OpponentsByCountryLive do
  use WololoWeb, :live_component
  alias Wololo.OpponentsByCountryAPI
  import WololoWeb.Components.Spinner

  def mount(socket) do
    {:ok, socket |> assign(profile_id: nil, countries: [], loading: true, error: nil)}
  end

  def update(assigns, socket) do
    case OpponentsByCountryAPI.fetch_last_50_player_games(assigns[:profile_id]) do
      {:ok, data} ->
        {
          :ok,
          socket
          |> assign(countries: data, loading: false, error: nil)
          |> push_event("update-player", %{byCountry: data})
        }

      {:error, reason} ->
        {
          :ok,
          socket
          |> assign(countries: [], loading: false, error: reason)
        }
    end
  end

  # def update(socket) do
  #   IO.inspect("Update function called")

  #   {:ok, data} = OpponentsByCountryAPI.fetch_last_50_player_games(socket.assigns.profile_id)

  #   {
  #     :noreply,
  #     socket
  #     |> assign(countries: data, loading: false, error: nil)
  #     |> push_event("update-player", %{byCountry: data})
  #   }
  # end
end
