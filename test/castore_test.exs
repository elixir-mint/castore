defmodule CAStoreTest do
  use ExUnit.Case
  doctest CAStore

  test "greets the world" do
    assert CAStore.hello() == :world
  end
end
