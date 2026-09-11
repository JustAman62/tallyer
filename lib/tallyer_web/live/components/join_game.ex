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
    <div>
      <.form for={@form} id="join-game-form" phx-submit="join_game" phx-target={@myself}>
        <.input type="text" autocomplete="off" field={@form[:username]} label="Name" required />
        <div class="flex justify-center">
          <button type="submit" class="btn btn-primary">Join Game</button>
        </div>
      </.form>
    </div>
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
  def handle_event("join_game", s(%{username}), socket) do
    send(self(), {:join_game, username})
    {:noreply, socket}
  end
end
