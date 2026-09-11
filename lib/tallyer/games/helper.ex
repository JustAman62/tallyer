defmodule Tallyer.Games.Helper do
  @moduledoc """
  Common methods for all games
  """

  import Destructure

  def handle_message(_, state), do: {:error, :unhandled, state}
end
