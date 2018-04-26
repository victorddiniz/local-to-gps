defmodule Credentials.Store do
  use Agent

  def start_link(opts) do
    case opts do
      [credentials_refresh_token: credentials_refresh_token] ->
        Agent.start_link(fn ->
          credentials_refresh_token
          |> get_new_state()
        end)
    end
  end

  def get_credentials(store) do
    Agent.get_and_update(store, fn state ->
      state = cond do
        update_is_required?(state) ->
          get_new_state(state)
        true ->
          state
      end
      {Map.fetch!(state, "access_token"), state}
    end)
  end

  defp update_is_required?(state) do
    now_time = DateTime.utc_now() |> DateTime.to_unix()
    %{
      "expires_in" => expires_in,
      "last_update" => last_update
    } = Map.take(state, ["expires_in", "last_update"])
    now_time - last_update >= expires_in
  end

  defp get_new_state(state) do
    Map.fetch!(state, "refresh_token")
    |> Google.OauthService.refresh_credentials()
    |> (&Map.merge(state, &1)).()
    |> Map.put("last_update", DateTime.utc_now() |> DateTime.to_unix())
  end
end
