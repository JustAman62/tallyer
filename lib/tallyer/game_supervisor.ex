defmodule Tallyer.GameSupervisor do
  use DynamicSupervisor

  import Destructure

  alias Tallyer.Games
  alias Tallyer.Utils

  require Logger

  @type creds :: %{id: String.t(), password: String.t()}

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def new_game(type) do
    game_module =
      case type do
        :scoreboard -> Games.Scoreboard
      end

    game_id = generate_game_id()

    Logger.info("Creating new #{type} game: #{game_id}")

    DynamicSupervisor.start_child(__MODULE__, {game_module, game_id: game_id, name: via(game_id)})

    game_id
  end

  def game_exists?(game_id), do: not is_nil(whereis_game(game_id))

  def game_type(game_id), do: send_message(game_id, :get_type)

  def join_game(game_id, username) do
    if game_exists?(game_id) do
      Phoenix.PubSub.subscribe(Tallyer.PubSub, Utils.GameId.topic(game_id))
      Logger.info("#{username} joining #{game_id}")

      :ok
    else
      {:error, :unknown_game}
    end
  end

  def send_message(game_id, message) do
    cond do
      pid = whereis_game(game_id) -> GenServer.call(pid, {:msg, message})
      true -> {:error, :game_not_found}
    end
  end

  defp generate_game_id do
    game_id = Utils.GameId.generate()

    # Make sure we haven't generated a game ID which already exists
    if whereis_game(game_id), do: generate_game_id(), else: game_id
  end

  defp whereis_game(game_id), do: GenServer.whereis(via(game_id))

  defp via(game_id), do: {:via, Registry, {Tallyer.GameRegistry, game_id}}
end
