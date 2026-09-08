defmodule TallyerWeb.Live.Components.JoinGame do
  @moduledoc """
  Shows a form asking the user to enter their name.
  Once submitted an event will be sent to the parent component `{:join_game, username}`.
  """

  use TallyerWeb, :live_component

  import Destructure

  @impl true
  def render(assigns) do
    ~H"""
    <.form for={@form} id="join-game-form" phx-submit="join_game">
      <.input type="text" field={@form[:username]} />
      <button type="submit" class="btn btn-primary">Join Game</button>
    </.form>
    """
  end

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:form, to_form(%{"username" => ""}))

    {:ok, socket}
  end

  @impl true
  def update(d(%{game_id}), socket) do
    {:ok, assign(socket, game_id: game_id)}
  end

  @impl true
  def handle_event("join_game", s(%{username}), socket) do
    send(self(), {:join_game, username})
    {:noreply, socket}
  end
end
