defmodule WololoWeb.InsightsLive do
  use WololoWeb, :live_component
  alias Wololo.PlayerGamesAPI
  import WololoWeb.Components.Spinner

  defp default_prompt(player_name) do
    """
    The prompt provided to you is a json object that contains data regarding an Age of Empires IV player profile. The player plays games on the ladder and gains/loses rating depending on the outcome.

    Your answer should provide 5 insights about this data. The insights should not be superficial, they should involve deeper reasoning about the statistics in the prompt. For example, you could answer that the player has a significantly higher winrate on weekeends than on weekdays. Or you could say that the player's winrate against opponents located in China is the lowest among all other countries.

    The format of your answer should be in html for easy parsing. Do not wrap the answer with any non-html syntax like ```. The parent container should be a <div> and there shouldn't be any <html> tags. Use <br /> for new lines and use tailwind classes. The 5 insights should be bullet points (use the `list-disc` tailwind class), with substantial bottom margin. Make it look modern and clean.

    Instead of using "the player" to refer to the player, use #{player_name} instead. Make the player's name bold.
    """
  end

  def call(_, %{:player_name => player_name, :prompt => prompt}) do
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

  defp parse_response({:ok, %Finch.Response{body: body}}) do
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

  defp parse_response(error) do
    error
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

  def mount(socket) do
    {:ok, socket |> assign(loading: true, error: nil, insights: nil)}
  end

  def update(assigns, socket) do
    IO.inspect(socket, label: ">>>>>>>>>>>>>>>>>>>LOADING")
    socket = assign(socket, loading: true)

    profile_id = assigns[:profile_id]
    player_name = assigns[:player_name]

    player_stats_result =
      PlayerGamesAPI.get_players_games_statistics(profile_id, false)

    case player_stats_result do
      {:ok, data} ->
        openai_completion = call(nil, %{player_name: player_name, prompt: data})
        IO.inspect(openai_completion, label: "openai_completion")

        {:ok,
         socket
         |> assign(insights: openai_completion["content"], loading: false, error: nil)}

      {:error, reason} ->
        {:ok,
         socket
         |> assign(insights: nil, loading: false, error: reason)}
    end
  end
end
