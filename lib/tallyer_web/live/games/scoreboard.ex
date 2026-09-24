defmodule TallyerWeb.Live.Games.Scoreboard do
  use TallyerWeb, :live_view

  import Destructure

  alias Tallyer.GameSupervisor
  alias Tallyer.Games.Scoreboard, as: Game
  alias Tallyer.Types.Player

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <%= cond do %>
        <% is_nil(@username) -> %>
          <.set_username_form />
        <% @game_state[:game_state] == :waiting_to_start -> %>
          <.waiting_to_start game={@game_state} />
        <% true -> %>
          Unknown
      <% end %>
    </Layouts.app>
    """
  end

  def set_username_form(assigns) do
    ~H"""
    <.form :let={f} for={%{}} phx-submit="submit_username">
      <.input field={f[:username]} label="Username" placeholder="John Smith" required autofocus />
      <div class="flex justify-center">
        <button type="submit" class="btn btn-primary">Join Game</button>
      </div>
    </.form>
    """
  end

  def waiting_to_start(assigns) do
    ~H"""
    <h2 class="text-xl font-bold text-center">Lobby</h2>
    <div class="flex flex-col">
      <.initial_player_state_form :for={player <- @game.players} player={player} />
    </div>
    """
  end

  def initial_player_state_form(%{player: d(%Player{player_id, name, score})} = assigns) do
    assigns =
      assigns
      |> assign(:form, to_form(s(%{player_id, name, score})))
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

  @impl true
  def mount(s(%{game_id}), _session, socket) do
    case GameSupervisor.join_game(game_id) do
      {:ok, game_pid} ->
        socket
        |> assign(game_pid: game_pid)
        |> assign(game_id: game_id)
        |> assign(username: nil)
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
        s(%{player_id, name, score}),
        %{assigns: d(%{game_pid, username})} = socket
      ) do
    with {player_id, _} <- Integer.parse(player_id),
         {score, _} <- Integer.parse(score) do
      Game.update_initial_player_state(game_pid, username, player_id, name, score)
      |> handle_game_response(socket)
      |> then(&{:noreply, &1})
    else
      _ ->
        socket
        |> put_flash(:warning, "Invalid values submitted")
        |> then(&{:noreply, &1})
    end
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
