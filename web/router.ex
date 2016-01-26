defmodule Ev3.Router do
  use Ev3.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Ev3 do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
  end

  scope "/api", Ev3 do
    pipe_through :api

    get "/robot/paused", RobotController, :paused?
    post "/robot/togglePaused", RobotController, :toggle_paused
  end
end
