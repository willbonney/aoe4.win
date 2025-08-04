defmodule WololoWeb.InsightsLive do
  use WololoWeb, :live_component
  alias Wololo.PlayerGamesAPI
  import WololoWeb.Components.Spinner

  defp default_prompt(player_name) do
    """
    The prompt provided to you is a json object that contains data regarding an Age of Empires IV player profile. The player plays games on the ladder and gains/loses rating depending on the outcome.

    Your answer should provide 5 insights about this data. The insights should not be superficial, they should involve deeper reasoning about the statistics in the prompt. For example, you could answer that the player has a significantly higher winrate on weekeends than on weekdays. Or you could say that the player's winrate against opponents located in China is the lowest among all other countries.

    Remember that the `country` key in the `player` object is a two-letter country code. You can use this to determine the country of the player's opponents. This is not the same as the `civilization` key, which is the civilization the player chose to play with.

    The format of your answer should be in html for easy parsing. Do not wrap the answer with any non-html syntax like ```. The parent container should be a <div> and there shouldn't be any <html> tags. Use <br /> for new lines and use tailwind classes. The 5 insights should be bullet points (use the `list-disc` tailwind class), with substantial bottom margin. Make it look modern and clean. Any html elements that contain text should include the following tailwind classes: `text-stone-900 dark:text-zinc-100`. Add `my-8` to each <li> element.

    Instead of using "the player" to refer to the player, use #{player_name} instead. Make the player's name bold.
    """
  end

  def call(_, %{:player_name => player_name, :prompt => prompt}) do
    cache_key = "openai_#{:crypto.hash(:md5, prompt) |> Base.encode16()}"

    case Cachex.get(:wololo_cache, cache_key) do
      {:ok, nil} ->
        # Cache miss, make the API call
        result = make_openai_request(player_name, prompt)
        Cachex.put(:wololo_cache, cache_key, result, ttl: :timer.hours(24))
        result

      {:ok, cached_result} ->
        # Cache hit, return the cached result
        cached_result

      {:error, _} ->
        # Error reading from cache, fall back to API call
        make_openai_request(player_name, prompt)
    end
  end

  defp make_openai_request(player_name, prompt) do
    %{
      "model" => "gpt-4o-mini",
      "messages" => [
        %{"role" => "system", "content" => default_prompt(player_name)},
        %{"role" => "user", "content" => prompt || ""}
      ],
      "temperature" => 0.7
    }
    |> Jason.encode!()
    |> request(nil)
    |> parse_response()
  end

  defp parse_response({:ok, %Finch.Response{status: 200, body: body}}) do
    IO.inspect(body, label: "body")

    messages =
      Jason.decode!(body)
      |> Map.get("choices", [])
      |> Enum.reverse()

    case messages do
      [%{"message" => message} | _] -> message
      _ -> "{}"
    end
  end

  defp parse_response({:ok, %Finch.Response{status: status_code}}) do
    Logger.error("OpenAI API request failed with status code: #{status_code}")
    {:error, "OpenAI API request failed with status code: #{status_code}"}
  end

  defp parse_response({:error, %Finch.Error{reason: reason}}) do
    Logger.error("OpenAI API request failed: #{reason}")
    {:error, "OpenAI API request failed: #{reason}"}
  end

  defp parse_response({:error, %Mint.TransportError{reason: reason}}) do
    Logger.error("OpenAI API request transport error: #{reason}")
    {:error, "OpenAI API request failed: connection timeout"}
  end

  defp parse_response({:error, error}) do
    Logger.error("OpenAI API request unexpected error: #{inspect(error)}")
    {:error, "OpenAI API request failed: unexpected error"}
  end

  defp parse_response(error) do
    Logger.error("OpenAI API request error: #{inspect(error)}")
    {:error, "OpenAI API request failed: #{inspect(error)}"}
  end

  defp request(body, _opts) do
    Finch.build(
      :post,
      "https://api.openai.com/v1/chat/completions",
      [
        {"Content-Type", "application/json"},
        {"Authorization", "Bearer #{Application.get_env(:wololo, :open_ai_api_key)}"}
      ],
      body
    )
    |> Finch.request(Wololo.Finch)
  end

  @impl true
  def mount(socket) do
    {:ok, socket |> assign(error: nil, insights: nil)}
  end

  @impl true
  def update(assigns, socket) do
    profile_id = assigns[:profile_id]
    player_name = assigns[:player_name]

    socket =
      socket
      |> assign(assigns)
      |> assign_async(:insights, fn -> fetch_insights(profile_id, player_name) end)

    {:ok, socket}
  end

  defp fetch_insights(profile_id, player_name) do
    case PlayerGamesAPI.get_players_games_statistics(profile_id, false) do
      {:ok, data} ->
        case call(nil, %{player_name: player_name, prompt: data}) do
          response when is_map(response) ->
            case Map.get(response, "content") do
              content when is_binary(content) ->
                {:ok, %{insights: content}}

              _ ->
                {:error, "Invalid response format from OpenAI"}
            end

          error ->
            {:error, "Unexpected response: #{inspect(error)}"}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end
end
