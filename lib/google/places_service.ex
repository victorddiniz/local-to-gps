defmodule Google.PlacesService do
  @url "https://maps.googleapis.com/maps/api/place/textsearch/json?"
  @key Keyword.fetch!(Application.get_env(:local_to_gps, GoogleCredentials), :places_api_key)
  def get_location_coordinates(text) do
    result =
      text
      |> URI.encode
      |> build_query
      |> HTTPoison.get!
      |> decode_body
      |> Map.fetch!("results")
      |> List.first
    case result do
      nil -> [lat: nil, lng: nil]
      _ ->
        lat = get_in(result, ["geometry", "location", "lat"])
        lng = get_in(result, ["geometry", "location", "lng"])
        [lat: lat, lng: lng]
    end
  end

  defp build_query(query) do
    "#{@url}key=#{@key}&query=#{query}"
  end

  defp decode_body(%HTTPoison.Response{status_code: 200, body: body}) do
    Poison.decode!(body)
  end

  defp decode_body(%HTTPoison.Response{status_code: _, body: _}) do
    %{"results" => []}
  end
end
