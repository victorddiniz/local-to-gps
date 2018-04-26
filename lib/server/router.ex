defmodule Server.Router do
  use Plug.Router

  plug :match
  plug :dispatch

  def init(opts) do
    IO.puts("Initializing plug")
    opts
  end

  get "/" do
    conn
    |> put_resp_header("Location", Google.OauthService.authorize_url())
    |> send_resp(301, "")
  end

  get "/aouth" do
    conn = fetch_query_params(conn)
    case conn.query_params do
      %{"code" => code} ->
        access_content = Google.OauthService.get_access_token(code)
        Map.fetch!(access_content, "refresh_token")
        |> Poison.encode_to_iodata!()
        |> (&File.write!("creds.json", &1)).()
        send_resp(conn, 200, "authorized")
      %{"error" => error} ->
        send_resp(conn, 200, error)
    end
  end

  match _ do
    send_resp(conn, 404, "no routers")
  end
end
