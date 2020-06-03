defmodule CAStoreTest do
  use ExUnit.Case
  doctest CAStore

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

  # 48 hours, in seconds
  @expiry_window 48 * 60 * 60

  test "file_path/0" do
    assert String.ends_with?(CAStore.file_path(), "/priv/cacerts.pem")
  end

  test "no expired or expiring certificates" do
    expired =
      CAStore.file_path()
      |> File.read!()
      |> :public_key.pem_decode()
      |> Enum.filter(&is_expired?/1)
      |> :public_key.pem_encode()

    # Assert on empty PEM string. In case of failure this will print the PEM
    # entry as found in the source file.
    assert "" = expired
  end

  defp is_expired?(pem_entry) do
    not_after =
      pem_entry
      |> :public_key.pem_entry_decode()
      |> certificate(:tbsCertificate)
      |> tbs_certificate(:validity)
      |> validity(:notAfter)
      |> parse_asn1_date_time()

    DateTime.diff(not_after, DateTime.utc_now()) < @expiry_window
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
