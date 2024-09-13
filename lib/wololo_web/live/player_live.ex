defmodule WololoWeb.PlayerLive do
  use WololoWeb, :live_view
  alias WololoWeb.SearchComponent
  alias WololoWeb.OpponentsByCountryLive
  alias WololoWeb.NumbersLive

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(active: nil, profile_id: nil, loading: true, error: nil, show: true)}
  end

  @impl true
  def handle_event("select-player", %{"id" => profile_id}, socket) do
    IO.inspect("select-player")

    {:noreply,
     socket
     |> assign(
       active: :opponents,
       profile_id: profile_id,
       loading: false,
       error: nil,
       show: false
     )}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    IO.inspect(params, label: "params")

    active =
      case params["section"] do
        "opponents" -> :opponents
        "rating" -> :rating
        _ -> :opponents
      end

    {:noreply, assign(socket, active: active)}
  end
end
