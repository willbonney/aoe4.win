defmodule WololoWeb.SearchComponent do
  use WololoWeb, :live_component
  import WololoWeb.CustomComponents
  import Wololo.SearchPlayerAPI

  @impl true
  def render(assigns) do
    ~H"""
    <div id="search-component">
      <.search_modal :if={@show} id="search-modal" show on_cancel={@on_cancel}>
        <.search_input phx-target={@myself} phx-keyup="do-search" phx-debounce="200" />
        <.search_results players={@players} hasSearched={@hasSearched} />
      </.search_modal>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok, assign(socket, players: [], show: true, hasSearched: false)}
  end

  # @impl true
  # def update(assigns, socket) do
  #   {
  #     :ok,
  #     socket
  #     |> assign(assigns)
  #   }
  # end

  @impl true
  def handle_event("do-search", %{"value" => value}, socket) do
    IO.inspect(value, label: "value")
    {response, data} = fetch_player(value)
    IO.inspect(response, label: "response")
    IO.inspect(data, label: "data")

    {
      :noreply,
      socket
      |> assign(search: value, players: data["players"], hasSearched: true)
    }
  end
end
