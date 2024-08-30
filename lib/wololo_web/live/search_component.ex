defmodule WololoWeb.SearchComponent do
  use WololoWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.search_modal :if={@show} id="search-modal" show on_cancel={@on_cancel}>
        <.search_input value={} phx-target={@myself} phx-keyup="do-search" phx-debounce="200" />
        <.search_results docs={} />
      </.search_modal>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok, socket, temporary_assigns: [docs: []]}
  end

  @impl true
  def update(assigns, socket) do
    {
      :ok,
      socket
      |> assign(assigns)
      #  |> assign_new(:documents, [])
      #  |> assign_new(:search, "")
    }
  end

  @impl true
  def handle_event("do-search", %{"value" => value}, socket) do
    IO.inspect(value, label: "value")

    {
      :noreply,
      socket
      |> assign(:search, value)
      #  |> assign(:documents, search_documents(value, socket.assigns.documents))
    }
  end
end
