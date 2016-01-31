defmodule Ev3.RobotChannel do
  @moduledoc "The channels with the EV3 robot"

  use Phoenix.Channel

  @runtime_stats_event "runtime_stats"

  def join("ev3:dashboard", _message, socket) do
    send(self(), :after_join)
    {:ok, socket}
  end

  def join("ev3:" <> _, _message, _socket) do
    {:error, %{reason: "Not implemented"}}
  end

  def handle_info(:after_join, socket) do
    stats = Ev3.runtime_stats()
    push(socket, @runtime_stats_event, stats)
    {:noreply, socket}
  end    
  
end
