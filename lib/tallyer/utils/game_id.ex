defmodule Tallyer.Utils.GameId do
  @moduledoc """
  Utilities for generating Game IDs.
  """

  @alphabet String.codepoints("ABCDEFGHKMNPQRTUVWXYZ")

  @doc """
  Generates a unique 6-character Game ID.
  The alphabet used to generate the ID is a subset of the english alphabet
  which excludes easy-to-mistake letters like i,l,s,o etc.
  """
  @spec generate() :: String.t()
  def generate do
    Stream.repeatedly(fn -> Enum.random(@alphabet) end)
    |> Enum.take(6)
    |> Enum.join()
  end

  def topic(game_id), do: "games:#{game_id}"
end
