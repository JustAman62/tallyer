defmodule Tallyer.Types.Player do
  @enforce_keys [:name, :score]
  defstruct [:name, :score]
end
