defmodule TallyerWeb.Live.GameRedirect do
  use TallyerWeb, :live_view

  import Destructure

  alias Tallyer.GameSupervisor

  @impl true
  def mount(s(%{game_id}), _session, socket) do
    socket =
      case GameSupervisor.game_type(game_id) do
        {:error, :game_not_found} ->
          socket
          |> push_navigate(to: "/")
          |> put_flash(:error, "Game #{game_id} not found")

        :scoreboard ->
          socket
          |> push_navigate(to: "/scoreboard/#{game_id}")
      end

    {:ok, socket}
  end
end
