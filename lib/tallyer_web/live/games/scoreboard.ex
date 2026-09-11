defmodule TallyerWeb.Live.Games.Scoreboard do
  use TallyerWeb, :live_view

  import Destructure

  alias Tallyer.GameSupervisor
  alias TallyerWeb.Live.Components

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <%= case @screen do %>
        <% :join_game -> %>
          <.live_component module={Components.JoinGame} id="join-game" />
        <% _ -> %>
          Unknown
      <% end %>
    </Layouts.app>
    """
  end

  @impl true
  def mount(s(%{game_id}), _session, socket) do
    if GameSupervisor.game_exists?(game_id) do
      socket =
        socket
        |> assign(game_id: game_id)
        |> assign(screen: :join_game)

      {:ok, socket}
    else
      socket =
        socket
        |> push_navigate(to: "/")
        |> put_flash(:error, "Game #{game_id} not found")

      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:join_game, username}, %{assigns: d(%{game_id})} = socket) do
    socket =
      case GameSupervisor.join_game(game_id, username) do
        :ok ->
          # Now that we've joined the game, we should expect to receive
          # messages from the game as join_game subscribes this process to it

          socket
          |> assign(username: username)
          |> assign(screen: :loading)

        {:error, reason} ->
          socket |> put_flash(:error, "Error: #{inspect(reason)}")
      end

    {:noreply, socket}
  end
end
