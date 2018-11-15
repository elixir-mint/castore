defmodule CAStore do
  @moduledoc """
  Documentation for CAStore.
  """

  @doc """
  Returns the path to the cacerts PEM file.
  """
  @spec file_path() :: Path.t()
  def file_path() do
    Application.app_dir(:castore, "priv/cacerts.pem")
  end
end
