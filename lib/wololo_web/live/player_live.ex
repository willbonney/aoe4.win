defmodule WololoWeb.PlayerLive do
  use WololoWeb, :live_view
  alias WololoWeb.SearchComponent
  alias WololoWeb.OpponentsByCountryLive

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(profile_id: nil, loading: true, error: nil, show: true)}
  end

  @impl true
  def handle_event("select-player", %{"id" => profile_id}, socket) do
    IO.inspect("select-player")

    {:noreply,
     socket
     |> assign(profile_id: profile_id, loading: false, error: nil, show: false)}
  end
end
