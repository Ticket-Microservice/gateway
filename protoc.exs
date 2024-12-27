defmodule Protoc do
  @shortdoc "Generates Protobuf and gRPC code from .proto files"

  def run do
    IO.inspect("Generating Protobuf and gRPC files...")

    proto_path = Path.join([File.cwd!(), "protos"])
    output_path = Path.join([File.cwd!(), "lib/protos/"])

    protos_file = [
      "#{proto_path}/register.proto",
      "#{proto_path}/healthcheck.proto"
    ]
    # Ensure output directory exists
    File.mkdir_p!(output_path)

    # Run protoc
    System.cmd("protoc", [
        "-I=#{proto_path}",
        # "-I=#{googleapis_path}",
        "--elixir_out=plugins=grpc,gen_descriptors=true:#{output_path}"
        # "#{proto_path}/greeting.proto",
        # "#{googleapis_path}/google/rpc/error_details.proto",
        # "#{googleapis_path}/google/rpc/status.proto",
      ] ++ protos_file)
    |> handle_protoc_output()
  end

  defp handle_protoc_output({output, 0}) do
    IO.inspect(output)
  end

  defp handle_protoc_output({error_output, _}) do
    IO.inspect("protoc failed with error:\n#{error_output}")
  end
end

Protoc.run()
