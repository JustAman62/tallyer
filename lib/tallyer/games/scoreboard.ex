defmodule Tallyer.Games.Scoreboard do
  use GenServer

  import Destructure

  alias Tallyer.GameSupervisor
  alias Tallyer.Types.Player

  require Logger

  @spec start_link(String.t()) :: GenServer.on_start()
  def start_link(d([game_id, name])) do
    GenServer.start_link(__MODULE__, game_id, name: name)
  end

  @impl true
  def init(game_id) do
    state = %{
      game_id: game_id,
      players: [
        %Player{
          player_id: 0,
          name: "Home",
          score: 0
        },
        %Player{
          player_id: 1,
          name: "Away",
          score: 0
        }
      ],
      log: [],
      game_state: :waiting_to_start
    }

    {:ok, state}
  end

  #

  def game_state(pid, username), do: GenServer.call(pid, {:msg, username, :game_state})

  def add_player(pid, username),
    do: GenServer.call(pid, {:msg, username, {:add_player, username}})

  def update_initial_player_state(pid, username, id, name, score),
    do: GenServer.call(pid, {:msg, username, {:update_player, id, name, score}})

  def start_gane(pid, username),
    do: GenServer.call(pid, {:msg, username, {:start_gane, username}})

  def add_points(pid, username, player_name, score),
    do: GenServer.call(pid, {:msg, {:add_points, username, player_name, score}})

  #

  @impl true
  def handle_call({:common, :game_type}, _from, state), do: {:reply, :scoreboard, state}

  def handle_call({:msg, username, payload}, _from, state) do
    Logger.info("[#{state.game_id}-#{username}]: #{inspect(payload)}")

    case handle_message(payload, username, state) do
      {:ok, new_state} ->
        if new_state != state, do: GameSupervisor.publish_new_state(state.game_id, new_state)
        {:reply, {:ok, new_state}, new_state}

      {error, state} ->
        {:reply, error, state}
    end
  end

  def handle_message(:game_state, _username, state), do: {state, state}

  def handle_message({:add_player, username}, username, state) do
    with :ok <- ensure_game_state(:waiting_to_start, state),
         {:error, :player_not_found} <- player_by_name(username, state) do
      state =
        state
        |> log_event(:player_joined, username, "Player #{username} added")
        |> Map.update!(:players, fn players ->
          max_id = Enum.max_by(players, & &1.player_id).player_id

          new_player = %Player{
            player_id: max_id + 1,
            name: username,
            score: 0
          }

          players ++ [new_player]
        end)

      {:ok, state}
    else
      :ok ->
        {
          {:error,
           """
           Player with name #{username} is already in this game
           """},
          state
        }

      {:error, :invalid_game_state} ->
        {
          {:error,
           """
           Cannot add a player after the game has started
           """},
          state
        }
    end
  end

  def handle_message({:update_player, id, name, score}, _username, d(%{players}) = state) do
    with :ok <- ensure_game_state(:waiting_to_start, state),
         {:ok, _player} <- player_by_id(id, state) do
      state =
        state
        |> update_player(id, fn %Player{} = p ->
          %Player{p | name: name, score: score}
        end)

      {:ok, state}
    else
      {:error, :player_not_found} ->
        {
          {:error,
           """
           Player not found
           """},
          state
        }

      {:error, :invalid_game_state} ->
        {
          {:error,
           """
           Cannot update a player after the game has started
           """},
          state
        }
    end
  end

  def handle_message({:start_game, username}, state) do
    with :ok <- ensure_game_state(:waiting_to_start, state) do
      state =
        state
        |> log_event(:game_started, username, "#{username} started the game")
        |> Map.put(:game_state, :in_progress)

      {:ok, state}
    else
      {:error, :invalid_game_state} ->
        {
          {:error,
           """
           Game already started
           """},
          state
        }
    end
  end

  def handle_message({:add_points, username, player_id, score_to_add}, state) do
    with :ok <- ensure_game_state(:in_progress, state),
         {:ok, player} <- player_by_id(player_id, state) do
      state =
        state
        |> log_event(:score_update, username, "Added #{score_to_add} points to #{player.name}")
        |> update_player(player_id, fn %Player{} = p ->
          %Player{p | score: p.score + score_to_add}
        end)

      {:ok, state}
    else
      {:error, :player_not_found} ->
        {
          {:error,
           """
           Player #{player_id} not found
           """},
          state
        }

      {:error, :invalid_game_state} ->
        {
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

  defp player_by_name(player_name, d(%{players})) do
    case Enum.find(players, &(&1.name == player_name)) do
      nil -> {:error, :player_not_found}
      %Player{} -> :ok
    end
  end

  defp player_by_id(player_id, d(%{players})) do
    case Enum.find(players, &(&1.player_id == player_id)) do
      nil -> {:error, :player_not_found}
      %Player{} = player -> {:ok, player}
    end
  end

  defp update_player(state, player_id, update_fn) do
    state
    |> Map.update!(:players, fn players ->
      index = Enum.find_index(players, &(&1.player_id == player_id))
      player = Enum.find(players, &(&1.player_id == player_id))
      updated = update_fn.(player)
      List.replace_at(players, index, updated)
    end)
  end

  #

  defp log_event(state, username, type, message) do
    Map.update!(state, :log, fn entries ->
      entry = d(%{username, type, message})
      [entry | entries]
    end)
  end
end
