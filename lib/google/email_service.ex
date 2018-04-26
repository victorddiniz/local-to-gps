defmodule Google.EmailService do
  @baseUrl "https://www.googleapis.com/gmail/v1/users/me/messages"
  @sendEmailUr "https://www.googleapis.com/upload/gmail/v1/users/me/messages/send"

  def get_unread_emails_id(access_token) do
    case build_unread_emails_url(access_token)
      |> HTTPoison.get!()
      |> decode_response() do
      %{"messages" => messages} ->
        messages
        |> Enum.map(&Map.fetch!(&1, "id"))
      %{"resultSizeEstimate" => 0} ->
        []
    end
      end

  def delete_email(access_token, email_id) do
    %HTTPoison.Response{status_code: status_code} =
      build_get_email_url(access_token, email_id)
      |> HTTPoison.delete!()
    case status_code do
      204 ->
        :ok
      _ ->
        :error
    end
  end

  def get_message_info(access_token, email_id) do
    %{"payload" => %{"parts" => parts, "headers" => headers}} =
      build_get_email_url(access_token, email_id)
      |> HTTPoison.get!()
      |> decode_response()
    attachment_list =
      parts
      |> Enum.map(&handle_part(&1))
      |> Enum.filter(fn id -> id != nil end)
    %{"value" => from} =
      Enum.find(headers, fn header -> match?(%{"name" => "From", "value" => _}, header) end)
      %{
        from: from,
      attachments_id_list: attachment_list
    }
  end

  def get_attachment_data(access_token, message_id, attachment_id) do
    %{"data" => data} =
      build_get_attachment_url(access_token, message_id, attachment_id)
      |> HTTPoison.get!()
      |> decode_response()
    data
    |> Base.url_decode64!()
  end

  def send_email_with_string_as_attachment(access_token, to, content) do
    headers = build_headers(access_token)
    body = build_upload_file_body(to, content)
    %{"id" => id} =
      build_upload_file_url()
      |> HTTPoison.post!(body, headers)
      |> decode_response()
    id
  end

  def put_email_to_trash(access_token, email_id) do
    headers = [
      {"Content-Type", "application/json"},
      {"Authorization", "Bearer #{access_token}"},
    ]
    %HTTPoison.Response{status_code: status_code} =
      build_trash_email_url(email_id)
      |> HTTPoison.post!("", headers)
    case status_code do
      200 ->
        :ok
      _ ->
        :error
    end
  end

  defp build_unread_emails_url(access_token) do
    q = URI.encode_www_form("is:unread")
    "#{@baseUrl}?access_token=#{access_token}&q=#{q}"
  end

  defp build_get_email_url(access_token, email_id) do
    "#{@baseUrl}/#{email_id}?access_token=#{access_token}"
  end

  defp build_get_attachment_url(access_token, email_id, attachment_id) do
    "#{@baseUrl}/#{email_id}/attachments/#{attachment_id}?access_token=#{access_token}"
  end

  defp build_trash_email_url(email_id) do
    "#{@baseUrl}/#{email_id}/trash"
  end

  defp build_upload_file_url() do
    "#{@sendEmailUr}?uploadType=media"
  end

  defp build_headers(access_token) do
    [
      {"Content-Type", "message/rfc822"},
      {"Authorization", "Bearer #{access_token}"},
    ]
  end

  defp build_upload_file_body(to, content) do
    encoded_content = Base.encode64(content)
    "To: #{to}\n" <>
    "From: localtogps.test@gmail.com\n" <>
    "Subject: Resultado do upload\n" <>
    "Content-Type: multipart/mixed; boundary=boundaryboundary\n\n" <>
    "--boundaryboundary\n" <>
    "Content-Type: text/plain; name=result.txt\n" <>
    "Content-Disposition: attachment; filename=result.txt\n" <>
    "Content-Transfer-Encoding: base64\n\n" <>
    "#{encoded_content}\n\n" <>
    "--boundaryboundary\n" <>
    "Content-Type: text/plain; charset=UTF-8\n" <>
    "Content-Transfer-Encoding: base64\n\n" <>
    "O resultado se encontra no anexo.\n\n" <>
    "--boundaryboundary--"
  end

  defp decode_response(%HTTPoison.Response{status_code: _, body: body}) do
    Poison.decode!(body)
  end

  defp handle_part(%{"body" => body}) do
    case body do
      %{"attachmentId" => attatchment_id} ->
        attatchment_id
        _ ->
          nil
    end
  end
end
