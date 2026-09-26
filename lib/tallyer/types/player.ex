defmodule Tallyer.Types.Player do
  @enforce_keys [:player_id, :name, :score, :colour]
  defstruct [:player_id, :name, :score, :colour]
end
