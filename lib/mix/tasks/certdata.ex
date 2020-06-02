defmodule Mix.Tasks.Certdata do
  @moduledoc """
  Fetches an up-to-date version of the CA certificate store.

  The certificate store is then stored in the private storage of this library. The path
  to the CA certificate store can be retrieved through `CAStore.file_path/0`.

  ## Usage

  You can use this task to fetch an up-to-date version of the CA certificate store.

      mix certdata

  You can also use this task to verify if the currently stored certificate store is
  up to date. To do that, use the `--check-outdated` option.

      mix certdata --check-outdated

  """

  use Mix.Task

  @shortdoc "Fetches an up-to-date version of the CA certificate store"

  @mk_ca_bundle_url "https://raw.githubusercontent.com/curl/curl/master/lib/mk-ca-bundle.pl"
  @mk_ca_bundle_cmd "mk-ca-bundle.pl"
  @ca_bundle "ca-bundle.crt"
  @ca_bundle_target "priv/cacerts.pem"
  @cert_exceptions ["AddTrust External Root"]

  @impl true
  def run(args)

  def run([]) do
    fetch_ca_bundle()
    apply_exceptions()
    File.rename(@ca_bundle, @ca_bundle_target)
  end

  def run(["--check-outdated"]) do
    fetch_ca_bundle()
    apply_exceptions()

    old_bundle = read_certificates_set(CAStore.file_path())
    new_bundle = read_certificates_set(@ca_bundle)

    File.rm!(@ca_bundle)

    if not MapSet.equal?(old_bundle, new_bundle) do
      Mix.raise("#{CAStore.file_path()} is outdated. Run \"mix certdata\" to update it.")
    end
  end

  def run(_args) do
    Mix.raise("Invalid arguments. See `mix help certdata`.")
  end

  defp fetch_ca_bundle do
    cmd!("wget #{@mk_ca_bundle_url}")

    try do
      File.chmod!(@mk_ca_bundle_cmd, 0o755)
      cmd!("#{Path.expand(@mk_ca_bundle_cmd)} -u")
    after
      File.rm!(@mk_ca_bundle_cmd)
    end
  end

  defp apply_exceptions() do
    bundle = File.read!(@ca_bundle)

    bundle =
      Enum.reduce(@cert_exceptions, bundle, fn cert, bundle ->
        Regex.replace(~r"\n#{cert}.*-----END CERTIFICATE-----\n"Us, bundle, "")
      end)

    File.write!(@ca_bundle, bundle)
  end

  defp cmd!(cmd) do
    Mix.shell().info([:magenta, "Running: #{cmd}"])

    exit_status = Mix.shell().cmd(cmd)

    if exit_status != 0 do
      Mix.raise("Non-zero result (#{exit_status}) from command: #{cmd}")
    end
  end

  defp read_certificates_set(path) do
    path
    |> File.read!()
    |> :public_key.pem_decode()
    |> MapSet.new()
  end
end
