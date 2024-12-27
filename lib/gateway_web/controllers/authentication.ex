defmodule GatewayWeb.Controller.Authentication do
  use GatewayWeb, :controller

  alias TicketAuthentications.LoginRequest
  alias TicketAuthentications.Register.Stub, as: RegisterStub
  alias GatewayWeb.GRPCClient

  require Logger

  def login(conn, params) do
    try do
      request = %LoginRequest{
        email: params["email"],
        pwd: params["pwd"]
      }

      # {:ok, channel} = GRPC.Stub.connect(System.get_env("AUTH_SERVICE"))
      # resp= channel |> RegisterStub.login(request)

      resp = GRPCClient.call_service({RegisterStub, :login}, request)
      |> IO.inspect()

      case resp do
        {:ok, response} ->
          conn
          |> put_status(:ok)
          |> json(%{
            data: %{
              token: response.jwt
            },
            message: "success"
          })

        {:error, msg} ->
          conn
          |> put_status(:internal_server_error)
          |> json(%{data: %{}, errors: [msg]})
      end
    rescue
      e ->
        Logger.error(e)

        conn
        |> put_status(:internal_server_error)
        |> json(%{message: e.message})
    end
  end
end
