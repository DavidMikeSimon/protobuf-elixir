defmodule Mix.Compilers.Protobuf do
  @manifest_id :protobuf_manifest_v1

  def compile(manifest, src_paths, dest, exts, force, opts) do
    timestamp = :calendar.universal_time()

    srcs = src_paths |> Mix.Utils.extract_files(exts) |> MapSet.new
    prev_srcs = read_manifest(manifest, dest)
    removed_srcs = MapSet.difference(prev_srcs, srcs)
    new_srcs = MapSet.difference(srcs, prev_srcs)

    changed_srcs = if force do
      srcs
    else
      prev_srcs
        |> Mix.Utils.extract_stale([manifest])
        |> MapSet.new
        |> MapSet.union(new_srcs)
        |> MapSet.difference(removed_srcs)
    end

    if MapSet.size(changed_srcs) > 0 do
      changed_srcs |> Enum.each(&build_beam/1)
    end
    
    write_manifest(manifest, srcs, timestamp)

    {changed_srcs, removed_srcs}
  end

  defp read_manifest(manifest, compile_path) do
    try do
      manifest |> File.read!() |> :erlang.binary_to_term()
    rescue
      _ -> MapSet.new()
    else
      { @manifest_id, srcs } -> MapSet.new(srcs)
      _ -> MapSet.new()
    end
  end

  defp write_manifest(manifest, srcs, timestamp) do
    manifest_data = 
      { @manifest_id, srcs }
      |> :erlang.term_to_binary([:compressed])

    File.mkdir_p!(Path.dirname(manifest))
    File.write!(manifest, manifest_data)
    File.touch!(manifest, timestamp)
  end

  defp build_beam(src) do
    Mix.shell.info("Compiling protobuf #{src}")
  end
end
