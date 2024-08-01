defmodule WololoWeb.CivsByMapHTML do
  use WololoWeb, :html

  embed_templates "civs_by_map_html/*"

  def civ_header(assigns) do
    ~H"""
    <div class="flex items-center flex-col">
      <img src={"/images/#{@civ}.png"} alt={@label} class="w-10 h-6 mr-2" />
      <span><%= @label %></span>
    </div>
    """
  end

  def bg_color(percentage) when is_binary(percentage) do
    case Float.parse(percentage) do
      {value, "%"} -> bg_color(value)
      # Default color for invalid input
      _ -> "bg-gray-100"
    end
  end

  def bg_color(percentage) when is_number(percentage) do
    cond do
      percentage < 45 -> "bg-red-500"
      percentage < 47 -> "bg-red-400"
      percentage < 49 -> "bg-red-300"
      percentage < 50 -> "bg-red-200"
      percentage == 50 -> "bg-gray-200"
      percentage < 51 -> "bg-green-200"
      percentage < 53 -> "bg-green-300"
      percentage < 55 -> "bg-green-400"
      true -> "bg-green-500"
    end
  end

  # Default color for any other input
  def bg_color(_), do: "bg-gray-100"
end
