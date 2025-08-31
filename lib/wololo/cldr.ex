defmodule Wololo.Cldr do
  @moduledoc """
  Cldr backend module for internationalization
  """

  use Cldr,
    locales: ["en", "fr", "de", "es", "ja", "ko", "zh", "ru"],
    default_locale: "en",
    providers: [Cldr.Number]
end
