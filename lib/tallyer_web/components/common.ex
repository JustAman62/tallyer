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
      <.link navigate="/" class="btn btn-error">Exit Game</.link>
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

  attr :id, :string
  attr :item_min_width, :integer
  attr :item_min_height, :integer
  attr :class, :string
  attr :rest, :global

  slot :inner_block

  def balanced_grid(assigns) do
    ~H"""
    <div
      id="balanced-grid"
      class={[
        "balanced-grid",
        @class
      ]}
      phx-hook=".BalancedGrid"
      data-min-width={@item_min_width}
      data-min-height={@item_min_height}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".BalancedGrid">
      export default {
        mounted() {
          this.updateColumns()

          this.handleResize = () => {
            this.updateColumns()
          }

          window.addEventListener("resize", this.handleResize)
        },

        updated() {
          this.updateColumns()
        },

        destroyed() {
          window.removeEventListener("resize", this.handleResize)
        },

        updateColumns() {
          const width = this.el.clientWidth
          const itemCount = this.el.children.length

          const minWidth = this.el.dataset.minWidth

          if (itemCount === 0) {
            this.el.style.setProperty("--columns", 1);
            return;
          }

          // Maximum number of columns that can physically fit.
          const maxColumns = Math.floor(
            (width) / (minWidth)
          )

          // Can't have more columns than items.
          const columns = Math.min(itemCount, maxColumns)

          // Now that we know how many rows we need, figure out
          // the number of columns that would fill in all the rows
          // as full as possible
          const numRows = Math.ceil(itemCount/columns)
          const optimalColumns = Math.ceil(itemCount/numRows)

          this.el.style.setProperty(
            "--columns",
            Math.max(1, optimalColumns)
          );
          this.el.style.setProperty(
            "--item-min-height",
            this.el.dataset.itemMinHeight
          );
        }
      }
    </script>
    """
  end
end
