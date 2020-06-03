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

  require Record

  Record.defrecord(
    :certificate,
    :Certificate,
    Record.extract(:Certificate, from_lib: "public_key/include/OTP-PUB-KEY.hrl")
  )

  Record.defrecord(
    :tbs_certificate,
    :TBSCertificate,
    Record.extract(:TBSCertificate, from_lib: "public_key/include/OTP-PUB-KEY.hrl")
  )

  Record.defrecord(
    :validity,
    :Validity,
    Record.extract(:Validity, from_lib: "public_key/include/OTP-PUB-KEY.hrl")
  )

  @shortdoc "Fetches an up-to-date version of the CA certificate store"

  @mk_ca_bundle_url "https://raw.githubusercontent.com/curl/curl/master/lib/mk-ca-bundle.pl"
  @mk_ca_bundle_cmd "mk-ca-bundle.pl"
  @ca_bundle "ca-bundle.crt"
  @ca_bundle_target "priv/cacerts.pem"

  @impl true
  def run(args)

  def run([]) do
    bundle =
      fetch_ca_bundle()
      |> parse_bundle()
      |> filter_expired()
      |> rebuild_bundle()

    File.write!(@ca_bundle_target, bundle)
  end

  def run(["--check-outdated"]) do
    new_bundle =
      fetch_ca_bundle()
      |> parse_bundle()
      |> filter_expired()
      |> rebuild_bundle()

    old_bundle = read_certificates_set(File.read!(CAStore.file_path()))
    new_bundle = read_certificates_set(new_bundle)

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
      File.read!(@ca_bundle)
    after
      File.rm!(@mk_ca_bundle_cmd)
      File.rm!(@ca_bundle)
    end
  end

  defp cmd!(cmd) do
    Mix.shell().info([:magenta, "Running: #{cmd}"])

    exit_status = Mix.shell().cmd(cmd)

    if exit_status != 0 do
      Mix.raise("Non-zero result (#{exit_status}) from command: #{cmd}")
    end
  end

  defp read_certificates_set(bundle) do
    bundle
    |> :public_key.pem_decode()
    |> MapSet.new()
  end

  defp parse_bundle(bundle) do
    lines = String.split(bundle, "\n", trim: true)
    {comments, bundle} = Enum.split_while(lines, &String.starts_with?(&1, "#"))
    {comments, chunk_certs(bundle, [])}
  end

  defp chunk_certs([name, "=" <> _ | lines], certs) do
    {cert, [_ | lines]} = Enum.split_while(lines, &(&1 != "-----END CERTIFICATE-----"))
    cert = {name, Enum.join(cert ++ ["-----END CERTIFICATE-----"], "\n")}
    chunk_certs(lines, [cert | certs])
  end

  defp chunk_certs([], certs) do
    Enum.reverse(certs)
  end

  defp rebuild_bundle({comments, certs}) do
    certs =
      Enum.map(certs, fn {name, cert} ->
        [name, ?\n, :lists.duplicate(String.length(name), ?=), ?\n, cert]
      end)

    [
      Enum.intersperse(comments, ?\n),
      "\n\n\n",
      Enum.intersperse(certs, "\n\n"),
      ?\n
    ]
  end

  defp filter_expired({comments, certs}) do
    certs = Enum.reject(certs, fn {_name, cert} -> expired?(:public_key.pem_decode(cert)) end)
    {comments, certs}
  end

  defp expired?([pem_entry]) do
    not_after =
      pem_entry
      |> :public_key.pem_entry_decode()
      |> certificate(:tbsCertificate)
      |> tbs_certificate(:validity)
      |> validity(:notAfter)
      |> parse_asn1_date_time()

    DateTime.to_unix(not_after) < DateTime.to_unix(DateTime.utc_now())
  end

  # Technically we would have to acount for utcTime values between 1950 and
  # 2000, but I think it is safe to ignore that here
  defp parse_asn1_date_time({:utcTime, date_time}) when length(date_time) == 13 do
    parse_asn1_date_time({:generalTime, [?2, ?0 | date_time]})
  end

  defp parse_asn1_date_time({:generalTime, date_time}) when length(date_time) == 15 do
    [y1, y2, y3, y4, m1, m2, d1, d2 | _] = date_time

    %DateTime{
      year: List.to_integer([y1, y2, y3, y4]),
      month: List.to_integer([m1, m2]),
      day: List.to_integer([d1, d2]),
      hour: 0,
      minute: 0,
      second: 0,
      time_zone: "Etc/UTC",
      zone_abbr: "UTC",
      utc_offset: 0,
      std_offset: 0
    }
  end
end
