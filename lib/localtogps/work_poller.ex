defmodule LocalToGps.WorkPoller do
  use Task

  def start_link(opts) do
    case opts do
      [creds_store_pid: store_pid] ->
        Task.start_link(fn ->
          poll_work(store_pid)
        end)
    end
  end

  defp poll_work(store_pid) do
    Credentials.Store.get_credentials(store_pid)
    |> Google.EmailService.get_unread_emails_id()
    |> Enum.map(fn email_id -> make_work(store_pid, email_id) end)
    Process.sleep(:timer.seconds(10))
    poll_work(store_pid)
  end

  defp make_work(store_pid, message_id) do
    LocalToGps.WorkProcessor.start([message_id: message_id, store_pid: store_pid])
  end
end
