defmodule Wololo.Utils do
  def rating_to_color_map(rating) do
    cond do
      rating < 500 -> "#B87333"
      rating < 700 -> "#C0C0C0"
      rating < 1000 -> "#FFC125"
      rating < 1200 -> "#E6E6E6"
      rating < 1400 -> "#87CEEB"
      rating > 1400 -> "#FF8C00"
    end
  end
end
