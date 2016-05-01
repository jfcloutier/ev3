defmodule Ev3.LegoSound do
  @moduledoc "Lego sound playing"

  require Logger
  alias Ev3.Device

  @sys_path "/sound"

  @doc "Get the available sound player devices"
  def sound_players() do
    [:speech]
    |> Enum.map(&(init_sound_player("#{&1}", "#{@sys_path}/#{&1}")))
  end

  @doc "Find a sound player device by type"
  def sound_player(type: type) do
    sound_players()
    |> Enum.find(&(type(&1) == type))
  end

  @doc "Get the type of the sound player device"
  def type(sound_player) do
    sound_player.type
  end

  @doc "Execute a cound command"
  def execute_command(sound_player, command, params) do
    spawn(fn -> apply(Ev3.LegoSound, command, [sound_player | params]) end)
    sound_player
  end

  @doc "The sound player says out loud the given words"
  def speak(sound_player, words) do
    speak(words, volume_level(sound_player), speed_level(sound_player), voice(sound_player))
  end

  @doc "Speak out words with a given volume, speed and voice"
  def speak(words, volume, speed, voice \\ "en") do
    case Ev3.platform() do
      :ev3 ->
        :os.cmd('espeak -a #{volume} -s #{speed} -v #{voice} "#{words}" --stdout | aplay')
      :brickpi ->
        Logger.warn("Can't speak out: ${words}")
      :dev ->
        args =  ["-a", "#{volume}", "-s", "#{speed}", "-v", "#{voice}", words]
        System.cmd("espeak", args)
    end
  end

  @doc "Speak words loud and clear"
  def speak(words) do
    speak(words, 300, 160)
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
