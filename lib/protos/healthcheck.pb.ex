defmodule HealthCheck.BlankResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "BlankResponse",
      field: [],
      nested_type: [],
      enum_type: [],
      extension_range: [],
      extension: [],
      options: nil,
      oneof_decl: [],
      reserved_range: [],
      reserved_name: [],
      __unknown_fields__: []
    }
  end
end

defmodule HealthCheck.HealthCheck.Service do
  @moduledoc false

  use GRPC.Service, name: "HealthCheck.HealthCheck", protoc_gen_elixir_version: "0.13.0"

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.ServiceDescriptorProto{
      name: "HealthCheck",
      method: [
        %Google.Protobuf.MethodDescriptorProto{
          name: "CheckHealth",
          input_type: ".HealthCheck.BlankResponse",
          output_type: ".HealthCheck.BlankResponse",
          options: %Google.Protobuf.MethodOptions{
            deprecated: false,
            idempotency_level: :IDEMPOTENCY_UNKNOWN,
            uninterpreted_option: [],
            __pb_extensions__: %{},
            __unknown_fields__: []
          },
          client_streaming: false,
          server_streaming: false,
          __unknown_fields__: []
        }
      ],
      options: nil,
      __unknown_fields__: []
    }
  end

  rpc :CheckHealth, HealthCheck.BlankResponse, HealthCheck.BlankResponse
end

defmodule HealthCheck.HealthCheck.Stub do
  @moduledoc false

  use GRPC.Stub, service: HealthCheck.HealthCheck.Service
end