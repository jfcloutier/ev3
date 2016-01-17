defmodule Ev3.LegoSound do
  @moduledoc "Lego sound playing"

  require Logger
  alias Ev3.Device

  @sys_path "/sound"

  @doc "Get the available sound players"
  def sound_players() do
    [:speech]
    |> Enum.map(&(init_sound_player("#{&1}", "#{@sys_path}/#{&1}")))
  end

  @doc "Find a sound player by type"
  def sound_player(type: type) do
    sound_players()
    |> Enum.find(&(type(&1) == type))
  end

  @doc "Get the type of the sound player"
  def type(sound_player) do
    sound_player.type
  end

  @doc "Execute a cound command"
  def execute_command(sound_player, command, params) do
    apply(Ev3.LegoSound, command, [sound_player | params])
    sound_player
  end

  @doc "The sound player says out loud the given words"
  def speak(sound_player, words) do
    if Ev3.testing? do
      args =  ["-a", "#{volume_level(sound_player)}", "-s", "#{speed_level(sound_player)}", "-v", "#{voice(sound_player)}", words]
      System.cmd("espeak", args)
    else
      :os.cmd('espeak -a #{volume_level(sound_player)} -s #{speed_level(sound_player)} -v #{voice(sound_player)} "#{words}" --stdout | aplay')
    end 
  end

  ### Private

  defp init_sound_player(type, path) do
    %Device{class: :sound,
            path: path,
            port: nil,
            type: type
           }
  end

  defp volume_level(sound_player) do
    case sound_player.props.volume do
      :low -> 50
      :normal -> 100
      :loud -> 500
    end
  end

  defp speed_level(sound_player) do
    case sound_player.props.speed do # words per minute
      :slow -> 80
      :normal -> 160
      :fast -> 320
    end
  end

  defp voice(sound_player) do
    sound_player.props.voice
  end
  
end
