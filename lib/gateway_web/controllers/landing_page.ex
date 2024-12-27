defmodule GatewayWeb.LandingPage do
  use GatewayWeb, :controller
  require Logger

  def index(conn, _params) do
    try do
      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(200, "Haii!")
    rescue
      e ->
        Logger.error(e)

        conn
        |> put_status(:internal_server_error)
        |> json(%{message: e.message})
    end
  end
end
