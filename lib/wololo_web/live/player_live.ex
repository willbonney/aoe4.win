defmodule WololoWeb.PlayerLive do
  use WololoWeb, :live_view
  alias WololoWeb.SearchComponent
  alias WololoWeb.OpponentsByCountryLive
  alias WololoWeb.NumbersLive

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       active: nil,
       profile_id: nil,
       name: nil,
       avatar: nil,
       site_url: nil,
       loading: true,
       error: nil,
       show: true
     )}
  end

  @impl true
  def handle_event(
        "select-player",
        %{"id" => profile_id, "name" => name, "avatar" => avatar, "url" => url},
        socket
      ) do
    IO.inspect("select-player")
    IO.inspect(avatar, label: "avatar")

    {:noreply,
     socket
     |> assign(
       active: :opponents,
       profile_id: profile_id,
       name: name,
       avatar: avatar,
       url: url,
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
