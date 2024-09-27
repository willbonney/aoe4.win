defmodule WololoWeb.PlayerLive do
  use WololoWeb, :live_view
  alias WololoWeb.SearchComponent
  alias WololoWeb.OpponentsByCountryLive
  alias WololoWeb.InsightsLive
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
       url: nil,
       rank: nil,
       wr: nil,
       error: nil,
       show_search: true
       #  loading: true
     )}
  end

  @impl true
  def handle_event(event, params, socket) do
    case event do
      "select-player" ->
        socket = assign(socket, show_search: false)
        send(self(), {:load_player_data, params})
        {:noreply, socket}

      "reset" ->
        {:noreply, socket |> assign(show: true)}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info(
        {:load_player_data,
         %{
           "id" => profile_id,
           "name" => name,
           "avatar" => avatar,
           "url" => url,
           "rank" => rank,
           "wr" => wr
         }},
        socket
      ) do
    # Assign all the player data here
    {:noreply,
     assign(socket,
       active: :insights,
       profile_id: profile_id,
       name: name,
       avatar: avatar,
       url: url,
       rank: rank,
       wr: wr,
       error: nil
     )}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    IO.inspect(params, label: "params")

    active =
      case params["section"] do
        "opponents" -> :opponents
        "rating" -> :rating
        "insights" -> :insights
        _ -> :insights
      end

    {:noreply, assign(socket, active: active)}
  end

  def render_section(assigns) do
    case assigns.active do
      :opponents ->
        ~H"""
        <.live_component
          module={OpponentsByCountryLive}
          id="opponents-by-country"
          profile_id={@profile_id}
        />
        """

      :rating ->
        ~H"""
        <.live_component module={NumbersLive} id="numbers" profile_id={@profile_id} />
        """

      :insights ->
        ~H"""
        <.live_component module={InsightsLive} id="insights" profile_id={@profile_id} player_name={@name} />
        """
    end
  end
end
