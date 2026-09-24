defmodule Tallyer.Types.Player do
  @enforce_keys [:player_id, :name, :score]
  defstruct [:player_id, :name, :score]
end
