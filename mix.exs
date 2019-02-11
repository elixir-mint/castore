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

      # Hex
      files: ["lib/castore.ex", "priv", "mix.exs", "README.md"],
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

  defp package do
    [
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => @repo_url}
    ]
  end
end
