defmodule CAStoreTest do
  use ExUnit.Case
  doctest CAStore

  test "file_path/0" do
    assert String.ends_with?(CAStore.file_path(), "/priv/cacerts.pem")
  end
end
