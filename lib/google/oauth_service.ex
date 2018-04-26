defmodule Google.OauthService do
  @url "https://accounts.google.com/o/oauth2/v2/auth"
  @tokenUrl "https://www.googleapis.com/oauth2/v4/token"
  @scopes ["https://mail.google.com/"]
  @clientId Keyword.fetch!(Application.get_env(:local_to_gps, GoogleCredentials), :oauth2_client_id)
  @clientSecret Keyword.fetch!(Application.get_env(:local_to_gps, GoogleCredentials), :oauth2_client_secret)

  def authorize_url() do
    build_query_string()
  end
    defp build_query_string() do
    scopes = URI.encode_www_form(Enum.join(@scopes, ""))
    redirect_url = URI.encode_www_form("http://localhost:4000/aouth")
    "#{@url}?scope=#{scopes}&access_type=offline&client_id=#{@clientId}&redirect_uri=#{redirect_url}&response_type=code"
  end

  def get_access_token(auth_code) do
    build_access_token_data(auth_code)
    |> data_to_token_url()
  end

  def refresh_credentials(refresh_token) do
    build_refresh_token_data(refresh_token)
    |> data_to_token_url()
  end

  defp data_to_token_url(data) do
    HTTPoison.post(@tokenUrl, data, [{"Content-Type", "application/x-www-form-urlencoded"}])
    |> handle_response
  end

  defp handle_response({:ok, %HTTPoison.Response{status_code: 200, body: body}}) do
    Poison.decode!(body)
  end

  defp build_access_token_data(auth_code) do
    redirect_url = "http://localhost:4000/aouth"
    "code=#{auth_code}&client_id=#{@clientId}&client_secret=#{@clientSecret}&redirect_uri=#{redirect_url}&grant_type=authorization_code"
  end

  defp build_refresh_token_data(refresh_token) do
    "client_id=#{@clientId}&client_secret=#{@clientSecret}&refresh_token=#{refresh_token}&grant_type=refresh_token"
  end
end
