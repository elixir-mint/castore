defmodule CAStoreTest do
  use ExUnit.Case
  doctest CAStore

  test "file_path/0" do
    assert String.ends_with?(CAStore.file_path(), "/priv/cacerts.pem")
  end

  test "cacerts/0" do
    cacerts = CAStore.cacerts()
    assert is_list(cacerts)
    assert length(cacerts) > 100

    for der <- cacerts do
      assert "-----BEGIN CERTIFICATE-----" <> _ =
               :public_key.pem_encode([{:Certificate, der, :not_encrypted}])
    end
  end
end
