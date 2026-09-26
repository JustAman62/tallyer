defmodule TallyerWeb.Live.Games.Scoreboard do
  use TallyerWeb, :live_view

  import Destructure

  alias Tallyer.GameSupervisor
  alias Tallyer.Games.Scoreboard, as: Game
  alias Tallyer.Types.Player
  alias Tallyer.Utils
  alias TallyerWeb.Components.Common

  @impl true
  def render(assigns) do
    ~H"""
    <%= if not is_nil(@username) and @game_state[:game_state] == :in_progress and @screen == :scoreboard_only do %>
      <.scoreboard_only game={@game_state} />
      <div class="mt-32 mb-8 flex justify-center">
        <button
          class="btn btn-primary "
          phx-click="change_screen"
          phx-value-screen={:manage_scores}
        >
          Back to Manage Scores
        </button>
      </div>
    <% else %>
      <Layouts.app flash={@flash}>
        <:sidebar>
          <Common.game_info :if={not is_nil(@username)} game={@game_state} username={@username} />
          <.game_settings_form :if={not is_nil(@username)} game={@game_state} />
        </:sidebar>

        <%= cond do %>
          <% is_nil(@username) -> %>
            <.set_username_form />
          <% @game_state[:game_state] == :waiting_to_start -> %>
            <.waiting_to_start game={@game_state} />
          <% @game_state[:game_state] == :in_progress and @screen == :manage_scores -> %>
            <.manage_scores game={@game_state} />
            <div class="mt-32 flex justify-center">
              <button
                class="btn btn-primary mt-32 mx-auto"
                phx-click="change_screen"
                phx-value-screen={:scoreboard_only}
              >
                Only Show Scoreboard
              </button>
            </div>
            <div class="flex mt-8">
              <Common.game_log game={@game_state} class="mx-auto" />
            </div>
          <% true -> %>
            Unknown
        <% end %>
      </Layouts.app>
    <% end %>
    """
  end

  defp set_username_form(assigns) do
    ~H"""
    <.form :let={f} for={%{}} phx-submit="submit_username" class="max-w-2xl mx-auto">
      <.input field={f[:username]} label="Username" placeholder="John Smith" required autofocus />
      <div class="flex justify-center">
        <button type="submit" class="btn btn-primary">Join Game</button>
      </div>
    </.form>
    """
  end

  defp waiting_to_start(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto">
      <h2 class="text-xl font-bold text-center">Lobby</h2>
      <div class="flex flex-col gap-8">
        <div>
          <.initial_player_state_form :for={player <- @game.players} player={player} />
        </div>

        <button type="button" class="btn btn-accent" phx-click="add_player">
          <.icon name="hero-plus" />
          <span>Add Player</span>
        </button>

        <div>
          <.game_settings_form game={@game} />
        </div>

        <div class="flex flex-col items-center">
          <p>Use the Game Code below to join on other devices</p>
          <Common.copy_button id="copy-game-id" value={@game.game_id} class="font-mono text-lg mt-4">
            Game Code: {@game.game_id}
          </Common.copy_button>
        </div>

        <button type="button" class="btn btn-primary" phx-click="start_game">
          <.icon name="hero-arrow-right" />
          <span>Start Game</span>
        </button>
      </div>
    </div>
    """
  end

  defp initial_player_state_form(%{player: d(%Player{player_id, name, score, colour})} = assigns) do
    assigns =
      assigns
      |> assign(:form, to_form(s(%{player_id, name, score, colour})))
      |> assign(:player_id, player_id)

    ~H"""
    <.form
      :let={f}
      for={@form}
      class="flex items-baseline-last gap-2 justify-center"
      phx-change="update_player"
    >
      <.input field={f[:player_id]} id={"player_id-#{@player_id}"} type="hidden" />
      <.input field={f[:name]} id={"name-#{@player_id}"} label="Name" required phx-debounce="1000" />
      <.input
        field={f[:colour]}
        type="color"
        class="w-full input p-0"
        id={"colour-#{@player_id}"}
        label="Colour"
        required
        phx-debounce="1000"
      />
      <.input
        field={f[:score]}
        id={"score-#{@player_id}"}
        label="Starting Score"
        type="number"
        required
        phx-debounce="1000"
      />
    </.form>
    """
  end

  defp game_settings_form(%{game: %{settings: d(%{score_system})}} = assigns) do
    assigns =
      assigns
      |> assign(:form, to_form(s(%{score_system})))
      |> assign(:score_systems, Utils.ScoreSystem.systems())

    ~H"""
    <.form
      :let={f}
      for={@form}
      class=""
      phx-change="update_game_settings"
    >
      <.input
        field={f[:score_system]}
        type="select"
        id="settings-score-system"
        options={@score_systems}
        label="Scoring System"
      />
    </.form>
    """
  end

  defp manage_scores(assigns) do
    ~H"""
    <Common.balanced_grid class="py-4 gap-8 min-h-screen" item_min_width={350} item_min_height={250}>
      <div
        :for={player <- @game.players}
        class="@container-size rounded-lg min-w-72 min-h-48 flex flex-col text-white grow overflow-hidden"
        style={"background-color: #{player.colour}"}
      >
        <h3 class="text-[min(8cqw,15cqh)] font-mono font-bold text-center">{player.name}</h3>
        <div class="text-[35cqh] font-mono font-semibold text-center my-auto">
          {player.score}
        </div>
        <Common.balanced_grid class="w-full" item_min_width={100} item_min_height={16}>
          <button
            :for={d(%{label, score, colour}) <- Utils.ScoreSystem.scores(@game.settings.score_system)}
            class="btn hover:opacity-80 h-12 rounded-none border-transparent"
            phx-click="update_score"
            phx-value-amount={score}
            label={score}
            phx-value-label={label}
            phx-value-player={player.player_id}
            style={"background-color: #{colour}"}
          >
            {label}
          </button>
        </Common.balanced_grid>
      </div>
    </Common.balanced_grid>
    """
  end

  defp scoreboard_only(assigns) do
    ~H"""
    <Common.balanced_grid class="min-h-screen" item_min_width={350} item_min_height={250}>
      <div
        :for={player <- @game.players}
        class="@container-size min-w-72 flex flex-col grow text-white"
        style={"background-color: #{player.colour}"}
      >
        <h3 class="text-[min(8cqw,15cqh)] font-mono font-bold text-center">{player.name}</h3>
        <div class="text-[35cqh] font-mono font-semibold text-center my-auto">
          {player.score}
        </div>
      </div>
    </Common.balanced_grid>
    """
  end

  @impl true
  def mount(s(%{game_id}), _session, socket) do
    case GameSupervisor.join_game(game_id) do
      {:ok, game_pid} ->
        socket
        |> assign(game_pid: game_pid)
        |> assign(game_id: game_id)
        |> assign(username: nil)
        |> assign(screen: :manage_scores)
        |> then(&{:ok, &1})

      {:error, :unknown_game} ->
        socket
        |> put_flash(:error, "Game #{game_id} not found")
        |> push_navigate(to: "/")
        |> then(&{:ok, &1})
    end
  end

  @impl true
  def handle_event("submit_username", s(%{username}), %{assigns: d(%{game_pid})} = socket) do
    socket
    |> assign(username: username)
    |> assign(game_state: Game.game_state(game_pid, username))
    |> then(&{:noreply, &1})
  end

  def handle_event(
        "update_player",
        s(%{player_id, name, score, colour}),
        %{assigns: d(%{game_pid, username})} = socket
      ) do
    with {player_id, _} <- Integer.parse(player_id),
         {score, _} <- Integer.parse(score) do
      Game.update_initial_player_state(game_pid, username, player_id, name, score, colour)
      |> handle_game_response(socket)
      |> then(&{:noreply, &1})
    else
      _ ->
        socket
        |> put_flash(:warning, "Invalid values submitted")
        |> then(&{:noreply, &1})
    end
  end

  def handle_event(
        "update_game_settings",
        s(%{score_system}),
        %{assigns: d(%{game_pid, username})} = socket
      ) do
    score_system = String.to_existing_atom(score_system)

    with true <- Utils.ScoreSystem.valid_system?(score_system) do
      Game.update_game_settings(game_pid, username, d(%{score_system}))
      |> handle_game_response(socket)
      |> then(&{:noreply, &1})
    else
      _ ->
        socket
        |> put_flash(:warning, "Invalid values submitted")
        |> then(&{:noreply, &1})
    end
  end

  def handle_event(
        "start_game",
        _params,
        %{assigns: d(%{game_pid, username})} = socket
      ) do
    Game.start_game(game_pid, username)
    |> handle_game_response(socket)
    |> then(&{:noreply, &1})
  end

  def handle_event(
        "add_player",
        _params,
        %{assigns: d(%{game_pid, username})} = socket
      ) do
    Game.add_player(game_pid, username)
    |> handle_game_response(socket)
    |> then(&{:noreply, &1})
  end

  def handle_event(
        "update_score",
        s(%{amount, label, player}),
        %{assigns: d(%{game_pid, username})} = socket
      ) do
    with {player_id, _} <- Integer.parse(player),
         {amount, _} <- Integer.parse(amount) do
      Game.add_points(game_pid, username, player_id, amount, label)
      |> handle_game_response(socket)
      |> then(&{:noreply, &1})
    else
      _ ->
        socket
        |> put_flash(:warning, "Failed to update score")
        |> then(&{:noreply, &1})
    end
  end

  def handle_event("change_screen", s(%{screen}), socket) do
    socket
    |> assign(:screen, String.to_existing_atom(screen))
    |> then(&{:noreply, &1})
  end

  defp handle_game_response({:ok, game_state}, socket),
    do: socket |> assign(:game_state, game_state)

  defp handle_game_response({:error, message}, socket),
    do: socket |> put_flash(:error, "Error: #{message}")

  @impl true
  def handle_info({:new_state, new_game_state}, %{assigns: d(%{game_state})} = socket) do
    if new_game_state != game_state do
      socket
      |> assign(:game_state, new_game_state)
      |> then(&{:noreply, &1})
    else
      {:noreply, socket}
    end
  end
end
