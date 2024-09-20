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
       rank: nil,
       wr: nil,
       error: nil,
       show: true
     )}
  end

  @impl true
  def handle_event(
        "select-player",
        %{
          "id" => profile_id,
          "name" => name,
          "avatar" => avatar,
          "url" => url,
          "rank" => rank,
          "wr" => wr
        },
        socket
      ) do
    IO.inspect("select-player")
    IO.inspect(url, label: "url")

    {:noreply,
     socket
     |> assign(
       active: :opponents,
       profile_id: profile_id,
       name: name,
       avatar: avatar,
       url: url,
       rank: rank,
       wr: wr,
       error: nil,
       show: false
     )}
  end

  def handle_event("reset", _, socket) do
    {:noreply, socket |> assign(show: true)}
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
