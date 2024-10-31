defmodule WololoWeb.PlayerLive do
  use WololoWeb, :live_view
  alias WololoWeb.SearchComponent
  alias WololoWeb.OpponentsByCountryLive
  alias WololoWeb.InsightsLive
  alias WololoWeb.RatingLive

  alias WololoWeb.GameLengthLive

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
        {:noreply, socket |> assign(show_search: true, profile_id: nil)}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info(
        {:load_player_data,
         %{"id" => profile_id, "name" => name, "avatar" => avatar, "url" => url} = player},
        socket
      ) do
    # Assign player data with optional rank and win rate
    {:noreply,
     assign(socket,
       active: :rating,
       profile_id: profile_id,
       name: name,
       avatar: avatar,
       url: url,
       rank: Map.get(player, "rank", nil),
       wr: Map.get(player, "wr", nil),
       error: nil
     )}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    active =
      case params["section"] do
        "opponents" -> :opponents
        "rating" -> :rating
        "insights" -> :insights
        "game_length" -> :game_length
        _ -> :rating
      end

    {:noreply, assign(socket, active: active)}
  end

  def render_section(assigns) do
    if(!assigns.profile_id) do
      ~H"""
      <div class="flex justify-center items-center h-full">
        <div class="spinner spinner-primary"></div>
      </div>
      """
    else
      case assigns.active do
        :rating ->
          ~H"""
          <.live_component module={RatingLive} id="rating" profile_id={@profile_id} />
          """

        :game_length ->
          ~H"""
          <.live_component
            module={GameLengthLive}
            id="game-length"
            profile_id={@profile_id}
            player_name={@name}
          />
          """

        :opponents ->
          ~H"""
          <.live_component
            module={OpponentsByCountryLive}
            id="opponents-by-country"
            profile_id={@profile_id}
          />
          """

        :insights ->
          ~H"""
          <.live_component module={InsightsLive} id="insights" profile_id={@profile_id} player_name={@name} />
          """
      end
    end
  end
end
