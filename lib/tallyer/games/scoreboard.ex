defmodule Tallyer.Games.Scoreboard do
  use GenServer

  import Destructure

  alias Tallyer.Types.Player

  @spec start_link(String.t()) :: GenServer.on_start()
  def start_link(d([game_id, name])) do
    GenServer.start_link(__MODULE__, game_id, name: name)
  end

  @impl true
  def init(game_id) do
    state = %{
      game_id: game_id,
      players: %{},
      # A list of ordered player_names for sorting purposes
      player_names: [],
      log: [],
      game_state: :waiting_to_start
    }

    {:ok, state}
  end

  #

  def add_player(pid, username), do: GenServer.call(pid, {:add_player, username})

  def add_points(pid, username, player_name, score),
    do: GenServer.call(pid, {:add_points, username, player_name, score})

  #

  @impl true
  def handle_call({:add_player, username}, _from, state) do
    with :ok <- ensure_game_state(:waiting_to_start, state),
         {:error, :player_not_found} <- ensure_player_exists(username, state) do
      state =
        state
        |> log_event(:player_joined, username, "Player #{username} added")
        |> Map.update!(:players, fn players ->
          new_player = %Player{
            name: username,
            score: 0
          }

          [new_player | players]
        end)

      {:reply, :ok, state}
    else
      :ok ->
        {
          :reply,
          {:error,
           """
           Player with name #{username} is already in this game
           """},
          state
        }

      {:error, :invalid_game_state} ->
        {
          :reply,
          {:error,
           """
           Cannot add a player after the game has started
           """},
          state
        }
    end
  end

  @impl true
  def handle_call({:start_game, username}, _from, state) do
    with :ok <- ensure_game_state(:waiting_to_start, state) do
      state =
        state
        |> log_event(:game_started, username, "#{username} started the game")
        |> Map.put(:game_state, :in_progress)

      {:reply, :ok, state}
    else
      {:error, :invalid_game_state} ->
        {
          :reply,
          {:error,
           """
           Game already started
           """},
          state
        }
    end
  end

  def handle_call({:add_points, username, player_name, score_to_add}, _from, state) do
    with :ok <- ensure_game_state(:in_progress, state),
         :ok <- ensure_player_exists(player_name, state) do
      state =
        state
        |> log_event(:score_update, username, "Added #{score_to_add} points to #{player_name}")
        |> Map.update!(:players, fn players ->
          players
          |> Map.update!(player_name, fn d(%Player{score}) = player ->
            %Player{player | score: score + score_to_add}
          end)
        end)

      {:reply, :ok, state}
    else
      {:error, :player_not_found} ->
        {
          :reply,
          {:error,
           """
           Player #{player_name} not found
           """},
          state
        }

      {:error, :invalid_game_state} ->
        {
          :reply,
          {:error,
           """
           Game must be started before points can be added to a player
           """},
          state
        }
    end
  end

  #

  defp ensure_game_state(expected_game_state, d(%{game_state}))
       when expected_game_state == game_state, do: :ok

  defp ensure_game_state(_, _), do: {:error, :invalid_game_state}

  defp ensure_player_exists(player_name, d(%{players})) do
    case Enum.find(players, &(&1 == player_name)) do
      nil -> {:error, :player_not_found}
      %Player{} -> :ok
    end
  end

  #

  defp log_event(state, username, type, message) do
    Map.update!(state, :log, fn entries ->
      entry = d(%{username, type, message})
      [entry | entries]
    end)
  end
end
