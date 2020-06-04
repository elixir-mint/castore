defmodule CAStore do
  @moduledoc """
  Functionality to retrieve the up-to-date CA certificate store.

  The only purpose of this library is to keep an up-to-date CA certificate store file.
  This is why this module only provides one function, `file_path/0`, to access the path of
  the CA certificate store file. You can then read this file and use its contents for your
  own purposes.
  """

  @doc """
  Returns the path to the CA certificate store PEM file.

  ## Examples

      CAStore.file_path()
      #=> /Users/me/castore/_build/dev/lib/castore/priv/cacerts.pem"

  """
  @spec file_path() :: Path.t()
  def file_path() do
    Application.app_dir(:castore, "priv/cacerts.pem")
  end

  @doc """
  Returns parsed CA certificates in a form suitable for Erlang SSL clients.

  Replaces `:certifi.cacerts/0`.

  ## Examples

      :hackney.request(:get, url, [], [], [ssl_options: [cacerts: CAStore.cacerts()]])

  """
  @spec cacerts() :: :ssl.client_cacerts()
  def cacerts() do
    file_path()
    |> File.read!()
    |> :public_key.pem_decode()
    |> Enum.map(fn {:Certificate, der, _} -> der end)
  end
end
