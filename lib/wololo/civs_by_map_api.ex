defmodule Wololo.CivsByMapAPI do
  @base_url Application.compile_env(:wololo, :api_base_url)

  def fetch_civs_by_map() do
    case Finch.build(:get, "#{@base_url}/stats/rm_solo/maps?include_civs=true")
         |> Finch.request(MyFinch) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        {:ok, IO.puts("Data type: #{inspect(body)}")}

      {:ok, %Finch.Response{status: status}} ->
        {:error, "Request failed with status code: #{status}"}

      {:error, reason} ->
        {:error, "Request failed: #{inspect(reason)}"}
    end
  end
end
