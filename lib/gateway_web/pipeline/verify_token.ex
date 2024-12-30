defmodule Gateway.Plugs.VerifyToken do
  use GatewayWeb, :controller
  alias TicketAuthentications.CheckTokenRequest
  alias TicketAuthentications.Register.Stub, as: RegisterStub
  alias GatewayWeb.GRPCClient

  def init(opts), do: opts

  def call(conn, _opts) do

    case Guardian.Plug.current_claims(conn) do
      %{"sub" => user_id} ->
        # IO.inspect(conn)
        request = %CheckTokenRequest{
          jwt: conn.private[:guardian_default_token],
          user_id: user_id
        }
        # |> IO.inspect(label: "plug")

        resp = GRPCClient.call_service({RegisterStub, :check_token}, request)
        |> IO.inspect()

        case resp do
          {:ok, response} ->
            cond do
              response.isValid -> conn
              !response.isValid ->
                conn
                |> put_status(:unauthorized)
                |> json(%{error: "Invalid or revoked token"}) # This now works
                |> halt()
            end

          {:error, msg} ->
            conn
            |> put_status(:internal_server_error)
            |> json(%{data: %{}, errors: [msg]})
        end
      _ ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Missing sub in claims"})
        |> halt()
    end
  end
end
