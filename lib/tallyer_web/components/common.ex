defmodule TallyerWeb.Components.Common do
  use TallyerWeb, :html

  import Destructure

  attr :game, :map
  attr :rest, :global

  def game_log(assigns) do
    ~H"""
    <table {@rest}>
      <thead>
        <tr>
          <th>Time</th>
          <th>User</th>
          <th>Message</th>
        </tr>
      </thead>
      <tr :for={d(%{timestamp, username, type, message}) <- @game.log}>
        <td class="p-1"><.local_time value={timestamp} /></td>
        <td class="p-1">{username}</td>
        <td class="p-1">{message}</td>
      </tr>
    </table>
    """
  end

  attr :game, :map
  attr :username, :string

  def game_info(assigns) do
    ~H"""
    <div class="flex flex-col my-8 gap-8 grow">
      <.copy_button id="copy-game-id" value={@game.game_id} class="font-mono text-lg">Game Code: {@game.game_id}</.copy_button>
      <div class="flex flex-col gap-4">
        <div :for={player <- @game.players} class="flex justify-between items-center">
          <span class="font-semibold text-xl">{player.name}</span>
          <span class="font-bold text-3xl font-mono">{player.score}</span>
        </div>
      </div>
      <div class="text-sm mt-auto">Username: {@username}</div>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :value, :string, required: true
  attr :class, :string, required: false, default: ""
  attr :rest, :global
  slot :inner_block, required: true

  def copy_button(assigns) do
    ~H"""
    <button
      id={@id}
      class={["btn btn-dash", @class]}
      type="button"
      phx-hook=".CopyButton"
      data-value={@value}
      title="Click to copy Game ID"
      {@rest}
    >
      {render_slot(@inner_block)}
      <.icon name="hero-clipboard" class="ml-auto" />
    </button>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".CopyButton">
      export default {
        mounted() {
          this.el.addEventListener("click", e => {
            navigator.clipboard.writeText(e.target.dataset.value);
          })
        }
      }
    </script>
    """
  end

  attr :value, DateTime, required: true

  def local_time(assigns) do
    ~H"""
    <time id={"#{@value}"} phx-hook=".LocalTime">{@value}</time>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".LocalTime">
      export default {
        mounted(){
          this.updated();
        },
        updated() {
          let dt = new Date(this.el.textContent);
          this.el.textContent = dt.toLocaleTimeString();
        }
      }
    </script>
    """
  end
end
