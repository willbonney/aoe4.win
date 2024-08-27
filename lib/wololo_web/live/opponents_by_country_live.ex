defmodule WololoWeb.OpponentsByCountry do
  use WololoWeb, :live_view
  alias Wololo.OpponentsByCountryAPI
  import WololoWeb.Components.Spinner

  @impl true
  def mount(params, session, socket) do
    data = OpponentsByCountryAPI.fetch_last_50_player_games()
    socket = assign(socket, data: data, loading: false, error: nil)
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%= if @loading do %>
        <.spinner />
      <% else %>
        <!-- render data here -->
        <canvas id="my-chart" phx-hook="ChartJS"></canvas>
      <% end %>
    </div>
    """
  end
end
