defmodule CAStore.MixProject do
  use Mix.Project

  @version "0.1.13"
  @repo_url "https://github.com/elixir-mint/castore"

  def project do
    [
      app: :castore,
      version: @version,
      elixir: "~> 1.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      xref: [exclude: [:public_key]],

      # Hex
      package: package(),
      description: "Up-to-date CA certificate store.",

      # Docs
      name: "CAStore",
      docs: [
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
      {:ex_doc, "~> 0.22", only: :dev}
    ]
  end

  defp package do
    [
      files: ["lib/castore.ex", "priv", "mix.exs", "README.md"],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @repo_url}
    ]
  end
end
