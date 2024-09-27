defmodule WololoWeb.SearchComponent do
  use WololoWeb, :live_component
  import WololoWeb.CustomComponents
  import Wololo.SearchPlayerAPI

  @impl true
  def mount(socket) do
    {:ok, assign(socket, search: "", players: [], has_searched: false)}
  end

  @impl true
  def handle_event("do-search", %{"value" => value}, socket) do
    {_, data} = fetch_player(value)

    {
      :noreply,
      socket
      |> assign(search: value, players: data["players"], has_searched: true)
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="search-component">
      <.search_modal show={assigns[:show]} id="search-modal" on_cancel={@on_cancel}>
        <.search_input phx-target={@myself} phx-keyup="do-search" phx-debounce="200" />
        <.search_results players={@players} has_searched={@has_searched} />
      </.search_modal>
    </div>
    """
  end
end
