defmodule Mix.Tasks.Compile.Protobuf do
  use Mix.Task

  @recursive true
  @manifest ".compile.protobuf"

  @switches [
    force: :boolean
  ]

  @spec run(OptionParser.argv) :: :ok | :noop
  def run(args) do
    project = Mix.Project.config
    config_srcs = project[:protobuf_srcs]

    {opts, _, _} = OptionParser.parse(args, switches: @switches)
    opts = Keyword.merge(project[:protobuf_options] || [], opts)

    manifest = manifest()
    dest = Mix.Project.compile_path(project)
    srcs = case config_srcs do
      paths when is_list(paths) -> paths
      nil -> ["proto"]
      _ -> Mix.raise ":srcs should be a list of paths, got: #{inspect(config_srcs)}"
    end

    configs = Mix.Project.config_files
    force = opts[:force] || Mix.Utils.stale?(configs, [manifest])

    case Mix.Compilers.Protobuf.compile(manifest, srcs, dest, [:proto], force, opts) do
      {[], []} -> :noop
      {_, _} -> :ok
    end
  end

  @doc """
  Returns Protobuf manifests.
  """
  def manifests, do: [manifest()]
  defp manifest, do: Path.join(Mix.Project.manifest_path, @manifest)

  @doc """
  Cleans up compilation artifacts.
  """
  def clean do
    dest = Mix.Project.compile_path
    # Mix.Compilers.Elixir.clean(manifest(), dest)
  end
end
