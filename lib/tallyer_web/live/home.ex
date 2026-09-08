defmodule TallyerWeb.Live.Home do
  use TallyerWeb, :live_view

  import Destructure

  @impl true
  def handle_event("create_game", s(%{game_type}), socket) do
    game_type = String.to_existing_atom(game_type)
    Tallyer.GameSupervisor.new_game(game_type)
    {:noreply, socket}
  end
end
