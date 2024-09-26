defmodule WololoWeb.PlayerLive do
  use WololoWeb, :live_view
  import WololoWeb.Components.Spinner
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
       show: true
       #  loading: true
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
       #  loading: true
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
        "insights" -> :insights
        _ -> :insights
      end

    {:noreply, assign(socket, active: active)}
  end

  # def handle_info({:set_loading, loading_state}, socket) do
  #   IO.inspect(loading_state, label: "loading_state")

  #   {:noreply, assign(socket, loading: loading_state)}
  # end

  @impl true
  def render_section(assigns) do
    IO.inspect(assigns, label: "assigns")

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
        <.live_component module={InsightsLive} id="insights" profile_id={@profile_id} />
        """
    end
  end
end
