defmodule TallyerWeb.Components.Common do
  use Phoenix.Component

  import Destructure

  attr :game, :map
  attr :rest, :global

  def game_log(assigns) do
    ~H"""
    <table {@rest}>
      <thead>
        <tr>
          <th>Time</th>
          <th>Username</th>
          <th>Type</th>
          <th>Message</th>
        </tr>
      </thead>
      <tr :for={d(%{timestamp, username, type, message}) <- @game.log}>
        <td class="p-1">{DateTime.to_iso8601(timestamp)}</td>
        <td class="p-1">{username}</td>
        <td class="p-1">{type}</td>
        <td class="p-1">{message}</td>
      </tr>
    </table>
    """
  end
end
