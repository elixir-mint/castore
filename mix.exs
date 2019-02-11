defmodule CAStore.MixProject do
  use Mix.Project

  @version "0.1.0"
  @repo_url "https://github.com/ericmj/castore"

  def project do
    [
      app: :castore,
      version: @version,
      elixir: "~> 1.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),

      # Hex
      package: package(),
      description: "Up-to-date CA certificate store.",

      # Docs
      name: "CAStore",
      docs: [
        main: "castore",
        source_ref: "v#{@version}",
        source_url: @repo_url
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.19.3", only: :dev}
    ]
  end

  defp aliases do
    [certdata: &certdata/1]
  end

  defp package do
    [
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => @repo_url}
    ]
  end

  @mk_ca_bundle_url "https://raw.githubusercontent.com/curl/curl/master/lib/mk-ca-bundle.pl"
  @mk_ca_bundle_cmd "mk-ca-bundle.pl"
  @ca_bundle "ca-bundle.crt"
  @ca_bundle_target "priv/cacerts.pem"

  defp certdata(_args) do
    cmd!("wget #{@mk_ca_bundle_url}")
    File.chmod!(@mk_ca_bundle_cmd, 0o755)

    cmd!("#{Path.expand(@mk_ca_bundle_cmd)} -u")

    File.rename(@ca_bundle, @ca_bundle_target)
    File.rm!(@mk_ca_bundle_cmd)
  end

  defp cmd!(cmd) do
    Mix.shell().info([:magenta, "Running: #{cmd}"])

    exit_status = Mix.shell().cmd(cmd)

    if exit_status != 0 do
      Mix.raise("Non-zero result (#{exit_status}) from command: #{cmd}")
    end
  end
end
