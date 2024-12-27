defmodule Gateway.GuardianPipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :gateway,
    module: Gateway.Guardian,
    error_handler: Gateway.GuardianErrorHandler

  plug(Guardian.Plug.VerifyHeader, realm: "Bearer")
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource
end
