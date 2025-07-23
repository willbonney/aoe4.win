defmodule WololoWeb.PlayerLive do
  use WololoWeb, :live_view
  alias WololoWeb.SearchComponent
  alias WololoWeb.OpponentsByCountryLive
  alias WololoWeb.InsightsLive
  alias WololoWeb.RatingLive
  alias Wololo.PlayerStatsAPI

  alias WololoWeb.GameLengthLive

  @initial_assigns [
    active: nil,
    profile_id: nil,
    name: nil,
    avatar: nil,
    url: nil,
    rank: nil,
    wr: nil,
    error: nil
  ]

  @impl true
  def mount(%{"profile_id" => profile_id} = _params, _session, socket)
      when not is_nil(profile_id) do
    send(self(), {:load_player_data, %{"id" => profile_id}})

    if connected?(socket) do
      :ok = Phoenix.PubSub.subscribe(Wololo.PubSub, "flash")
    end

    {:ok,
     assign(
       socket,
       @initial_assigns ++
         [show_search: false, current_url: url(socket, ~p"/player/#{profile_id}/rating")]
     )}
  end

  def mount(_params, _session, socket) do
    {:ok,
     assign(
       socket,
       @initial_assigns ++ [show_search: true, current_url: url(socket, ~p"/player")]
     )}
  end

  @impl true
  def handle_event("select-player", params, socket) do
    socket = assign(socket, show_search: false)
    send(self(), {:load_player_data, params})

    {:noreply,
     push_patch(socket,
       to: ~p"/player/#{params["id"]}/rating",
       replace: true
     )}
  end

  @impl true
  def handle_event(event, _params, socket) do
    case event do
      "reset" ->
        {:noreply, socket |> assign(show_search: true, profile_id: nil)}

      "copy_success" ->
        {:noreply, put_flash(socket, :info, "Copied player link to clipboard!")}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:load_player_data, %{"id" => profile_id}}, socket) do
    {:ok, stats} = PlayerStatsAPI.fetch_player_data(profile_id)

    {:noreply,
     socket
     |> assign(
       active: :rating,
       profile_id: profile_id,
       name: stats["name"],
       avatar: get_in(stats, ["avatars", "medium"]),
       url: stats["site_url"],
       rank: get_in(stats, ["modes", "rm_solo", "rank"]),
       wr: get_in(stats, ["modes", "rm_solo", "win_rate"]),
       error: nil,
       show_search: false,
       current_url: url(socket, ~p"/player/#{profile_id}/rating")
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
        "rank" -> :rank
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

        :rank ->
          ~H"""
          <.live_component module={RankLive} id="rank" profile_id={@profile_id} />
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

        _ ->
          ~H"""
          <div>Unknown section</div>
          """
      end
    end
  end
end
