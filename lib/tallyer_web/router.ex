defmodule TallyerWeb.Router do
  use TallyerWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {TallyerWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", TallyerWeb do
    pipe_through :browser

    live "/", Live.Home
    live "/scoreboard/:game_id", Live.Games.Scoreboard
    live "/:game_id", Live.GameRedirect
  end
end
