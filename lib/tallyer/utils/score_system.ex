defmodule Tallyer.Utils.ScoreSystem do
  @systems %{
    rugby: %{
      label: "Rugby",
      scores: [
        %{label: "Try", score: 5, colour: "#06D672"},
        %{label: "Conversion", score: 2, colour: "#06D6A0"},
        %{label: "Penalty Kick", score: 3, colour: "#EF476F"},
        %{label: "Drop Goal", score: 3, colour: "#f4b522"}
      ]
    },
    one_two_three: %{
      label: "One, Two, Three",
      scores: [
        %{label: "+1", score: 1, colour: "#60FBB0"},
        %{label: "+2", score: 2, colour: "#38FA9C"},
        %{label: "+3", score: 3, colour: "#05C769"}
      ]
    },
    one_thru_then: %{
      label: "One thru Ten",
      scores: [
        %{label: "+1", score: 1, colour: "#05C769"},
        %{label: "+2", score: 2, colour: "#05C769"},
        %{label: "+3", score: 3, colour: "#05C769"},
        %{label: "+4", score: 4, colour: "#05C769"},
        %{label: "+5", score: 5, colour: "#05C769"},
        %{label: "+6", score: 6, colour: "#05C769"},
        %{label: "+7", score: 7, colour: "#05C769"},
        %{label: "+8", score: 8, colour: "#05C769"},
        %{label: "+9", score: 9, colour: "#05C769"},
        %{label: "+10", score: 10, colour: "#05C769"}
      ]
    }
  }

  def systems do
    @systems |> Enum.map(fn {name, %{label: label}} -> {label, name} end)
  end

  def valid_system?(system_key) when is_binary(system_key),
    do: valid_system?(String.to_existing_atom(system_key))

  def valid_system?(system_key) when is_atom(system_key), do: Map.has_key?(@systems, system_key)

  def scores(system), do: @systems[system].scores
end
