defmodule Mix.Compilers.Protobuf do
  @manifest_id :protobuf_manifest_v1

  defmodule ManifestLine do
    defstruct path: nil, beam: nil
  end

  def compile(manifest_path, src_paths, dest, exts, force, opts) do
    timestamp = :calendar.universal_time()

    srcs = src_paths |> Mix.Utils.extract_files(exts) |> MapSet.new
    prev_manifest = read_manifest(manifest_path, dest)
    prev_srcs = Enum.map(prev_manifest, &(&1.path)) |> MapSet.new
    removed_srcs = MapSet.difference(prev_srcs, srcs)
    new_srcs = MapSet.difference(srcs, prev_srcs)

    changed_srcs = if force do
      srcs
    else
      prev_srcs
        |> Mix.Utils.extract_stale([manifest_path])
        |> MapSet.new
        |> MapSet.union(new_srcs)
        |> MapSet.difference(removed_srcs)
    end

    build_env = cond do
      MapSet.size(changed_srcs) > 0 -> prepare_build_env()
      true -> nil
    end

    { dead_manifest, keep_manifest } = prev_manifest |>
      Enum.split_with(&(MapSet.member?(removed_srcs, &1)))

    dead_manifest |> Enum.each(&clean_beam/1)

    changes_manifest = changed_srcs |> Enum.map(&(build_beam(build_env, &1)))

    updated_manifest = keep_manifest ++ changes_manifest
    write_manifest(manifest_path, updated_manifest, timestamp)

    {changed_srcs, removed_srcs}
  end

  def clean(manifest_path, dest) do
    # TODO
  end

  defp read_manifest(manifest_path, compile_path) do
    try do
      manifest_path |> File.read!() |> :erlang.binary_to_term()
    rescue
      _ -> MapSet.new()
    else
      { @manifest_id, lines } -> MapSet.new(lines)
      _ -> MapSet.new()
    end
  end

  defp write_manifest(manifest_path, lines, timestamp) do
    manifest_data = 
      { @manifest_id, lines }
      |> :erlang.term_to_binary([:compressed])

    File.mkdir_p!(Path.dirname(manifest_path))
    File.write!(manifest_path, manifest_data)
    File.touch!(manifest_path, timestamp)
  end

  defp prepare_build_env() do
    # TODO
  end

  defp build_beam(build_env, src) do
    Mix.shell.info("Compiling protobuf #{src}")

    # TODO

    %ManifestLine{ path: src, beam: nil }
  end

  defp clean_beam(manifest_line) do
    # TODO
  end
end
