defmodule TallyerWeb.Live.Home do
  use TallyerWeb, :live_view

  import Destructure

  @impl true
  def handle_event("create_game", s(%{value}), socket) do
    game_type = String.to_existing_atom(value)
    game_id = Tallyer.GameSupervisor.new_game(game_type)

    socket = socket |> redirect(to: ~p"/#{game_id}")

    {:noreply, socket}
  end
end
