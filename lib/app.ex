defmodule App do
  def main(_opts) do
    refresh_token = Keyword.fetch!(Application.get_env(:local_to_gps, GoogleCredentials), :oauth2_refresh_token)
    {:ok, store_pid} = Credentials.Store.start_link([credentials_refresh_token: refresh_token])
    LocalToGps.WorkPoller.start_link([creds_store_pid: store_pid])
    Process.sleep(:infinity)
  end
end
