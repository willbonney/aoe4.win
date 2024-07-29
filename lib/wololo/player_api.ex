defmodule Wololo.PlayerAPI do
  import HTTPoison

  @base_url Application.compile_env(:wololo, :api_base_url)

  @doc """
  Fetches a player by their ID.
  """
  def fetch_player(id) do
    case get("#{@base_url}/players/#{id}") do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, process_player(body)}

      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        {:error, "Request failed with status code: #{status_code}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "Request failed: #{reason}"}
    end
  end

  @expected_fields ~w(avatars country modes)a

  def process_player(body) do
    body
    |> Jason.decode!()
    |> then(fn decoded ->
      for field <- @expected_fields,
          value = Map.get(decoded, to_string(field)),
          value != nil,
          into: %{} do
        {field, value}
      end
    end)
    |> tap(&IO.inspect(&1, label: "Final processed player data"))
  end
end
