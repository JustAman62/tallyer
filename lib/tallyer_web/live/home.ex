defmodule TallyerWeb.Live.Home do
  use TallyerWeb, :live_view

  import Destructure

  alias Tallyer.GameSupervisor

  @impl true
  def handle_event("create_game", s(%{value}), socket) do
    game_type = String.to_existing_atom(value)
    game_id = Tallyer.GameSupervisor.new_game(game_type)

    socket = socket |> redirect(to: ~p"/#{game_id}")

    {:noreply, socket}
  end

  @impl true
  def handle_event("join_game", s(%{game_id}), socket) do
    case GameSupervisor.join_game(game_id) do
      {:ok, _game_pid} ->
        socket
        |> push_navigate(to: ~p"/#{game_id}")
        |> then(&{:noreply, &1})

      {:error, :unknown_game} ->
        socket
        |> put_flash(:error, "Game #{game_id} not found")
        |> then(&{:noreply, &1})
    end
  end
end
