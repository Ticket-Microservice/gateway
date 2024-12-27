defmodule GatewayWeb.GRPCClient do
  use GenServer
  require Logger
  alias GRPC.Stub
  alias HealthCheck.HealthCheck.Stub, as: HealthStub
  alias HealthCheck.BlankResponse, as: HealthResp
  alias Loggers

  @grpc_server System.get_env("AUTH_SERVICE")
  @health_check_interval 100_000  # Check every 10 seconds
  @reconnect_interval 5_000     # Reconnect delay in milliseconds

  # Public API
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def call_service(method, request) do
    GenServer.call(__MODULE__, {:call_service, method, request})
  end

  # GenServer Callbacks
  @impl true
  def init(_) do
    case connect_to_grpc() do
      {:ok, channel} ->
        # Start monitoring the connection
        IO.inspect("connected")
        schedule_health_check()
        {:ok, %{channel: channel, reconnect_attempts: 0}}

      {:error, _reason} ->
        # Schedule a reconnect if the initial connection fails
        IO.inspect("Unable to connect")
        schedule_reconnect()
        {:ok, %{channel: nil, reconnect_attempts: 0}}
    end
  end

  @impl true
  def handle_call({:call_service, method, request}, _from, %{channel: nil} = state) do
    # Return an error if not connected
    {:reply, {:error, :login_not_connected}, state}
  end

  def handle_call({:call_service, method, request}, _from, %{channel: channel} = state) do
    # Attempt the gRPC call
    response =
      case method do
        {module, function} ->
          apply(module, function, [channel, request])
      end

    case response do
      {:ok, _result} ->
        {:reply, response, state}

      {:error, _reason} ->
        # Mark the connection as failed and schedule reconnect
        # schedule_reconnect()
        {:reply, {:error, :login_connection_failed}, %{state | channel: nil}}
    end
  end

  # Handle periodic health checks
  @impl true
  def handle_info(:health_check, %{channel: nil} = state) do
    # Skip health check if not connected, try reconnecting instead
    schedule_reconnect()
    {:noreply, state}
  end

  def handle_info(:health_check, %{channel: channel} = state) do
    case perform_health_check(channel) do
      :ok ->
        # Reschedule health check if the connection is healthy
        schedule_health_check()
        {:noreply, state}

      :error ->
        # Schedule reconnect if health check fails

        schedule_reconnect()
        {:noreply, %{state | channel: nil}}
    end
  end

  # Handle reconnect attempts
  @impl true
  def handle_info(:reconnect, state) do
    case connect_to_grpc() do
      {:ok, channel} ->
        # Reset reconnect attempts on successful connection
        Logger.info(@grpc_server <> " reconnected")
        schedule_health_check()
        {:noreply, %{state | channel: channel, reconnect_attempts: 0}}

      {:error, _reason} ->
        Logger.error(@grpc_server <> " unable ro reconnect")
        # Retry with exponential backoff
        backoff = exponential_backoff(state.reconnect_attempts)
        schedule_reconnect(backoff)
        {:noreply, %{state | reconnect_attempts: state.reconnect_attempts + 1}}
    end
  end

  # Private helper to connect to gRPC server
  defp connect_to_grpc() do
    Stub.connect(@grpc_server)
  end

  # Private helper to perform health checks
  defp perform_health_check(channel) do
    # Replace this with your gRPC server's health-check endpoint or a lightweight call
    case HealthStub.check_health(channel, %HealthResp{}) do
      {:ok, _response} -> :ok
      {:error, _reason} -> :error
    end
  end

  # Private helper to schedule health checks
  defp schedule_health_check() do
    Process.send_after(self(), :health_check, @health_check_interval)
  end

  # Private helper to schedule reconnections
  defp schedule_reconnect(delay \\ @reconnect_interval) do
    Process.send_after(self(), :reconnect, delay)
  end

  # Exponential backoff calculation
  defp exponential_backoff(attempts) do
    :math.pow(2, attempts) * @reconnect_interval
    |> round()
    |> min(60_000)  # Cap at 60 seconds
  end
end
