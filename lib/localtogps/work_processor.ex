defmodule LocalToGps.WorkProcessor do
  def start(opts) do
    case opts do
      [message_id: message_id, store_pid: store_pid] ->
        Task.start(fn ->
          mark_as_processing(store_pid, message_id)
          %{from: from, attachments_id_list: attachments_id} =
            get_message_info(store_pid, message_id)
          content =
            attachments_id
            |> List.first()
            |> (&get_attachment_content(store_pid, message_id, &1)).()
            |> String.split("\n")
            |> Enum.filter(fn str -> String.length(str) > 0 end)
            |> Enum.map(&Google.PlacesService.get_location_coordinates(&1))
            |> Enum.map_join("\n", fn [lat: lat, lng: lng] -> "#{lat},#{lng}" end)
          send_email_with_coordinates(store_pid, from, content)
          delete_solved_message(store_pid, message_id)
        end)
    end
  end

  defp get_message_info(store_pid, message_id) do
    Credentials.Store.get_credentials(store_pid)
    |> Google.EmailService.get_message_info(message_id)
  end

  defp get_attachment_content(store_pid, message_id, attachment_id) do
    Credentials.Store.get_credentials(store_pid)
    |> Google.EmailService.get_attachment_data(message_id, attachment_id)
  end

  defp send_email_with_coordinates(store_pid, to, content) do
    Credentials.Store.get_credentials(store_pid)
    |> Google.EmailService.send_email_with_string_as_attachment(to, content)
  end

  defp delete_solved_message(store_pid, message_id) do
    Credentials.Store.get_credentials(store_pid)
    |> Google.EmailService.delete_email(message_id)
  end

  defp mark_as_processing(store_pid, message_id) do
    Credentials.Store.get_credentials(store_pid)
    |> Google.EmailService.put_email_to_trash(message_id)
  end
end
