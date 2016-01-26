defmodule Ev3.RobotController do
  @moduledoc "Robot API controller"

  use Phoenix.Controller

  alias Ev3.CNS

  @doc "Is the robot paused?"
  def paused?(conn, _params) do
    json(conn, %{paused: CNS.paused?()})
  end

  @doc "Toggle on/off the paused status of the robot"
  def toggle_paused(conn, _params) do
    json(conn, CNS.toggle_paused())
  end

end
