defmodule Wololo.Utils do
  def rating_to_color_map(rating) do
    cond do
      rating == "N/A" -> "#DDDDDD"
      rating <= 499 -> "#B87333"
      rating <= 699 -> "#C0C0C0"
      rating <= 999 -> "#FFC125"
      rating <= 1199 -> "#E6E6E6"
      rating <= 1399 -> "#87CEEB"
      true -> "#FF8C00"
    end
  end
end
