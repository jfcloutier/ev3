defmodule Ev3.InfraredSensor do
	@moduledoc "Infrared sensor"

	import Ev3.Sysfs
	alias Ev3.LegoSensor

	@proximity "IR-PROX"
	@seek "IR-SEEK"
  @remote "IR-REMOTE"

	@doc "Get proximity as a percent - range is 70cm"
  def proximity(sensor) do
		set_proximity_mode(sensor)
		get_attribute(sensor, "value0", :integer)
  end

	@doc "Get beacon heading on a channel 
    (-25 for far left, 25 for far right, 
     0 if absent or straight ahead)"
  def seek_heading(sensor, channel) when channel in 1 .. 4 do 
	set_seek_mode(sensor)
	get_attribute(sensor, "value#{(channel - 1) * 2}", :integer)
  end

	@doc "Get beacon distance on a channel 
  (as percentage, or -128 if absent)"
  def seek_distance(sensor, channel) when channel in 1 .. 4 do
		set_seek_mode(sensor)
		get_attribute(sensor, "value#{((channel - 1) * 2) + 1}", :integer)
  end

  @doc "Is the beacon on in seek mode?"
	def seek_beacon_on?(sensor, channel) when channel in 1 .. 4 do
		seek_distance(sensor, channel) == -128 && seek_heading(sensor, channel) == 0
  end

	@doc "Get remote button pushed (maximum two buttons) on a channel. 
  (E.g. %{red: :up, blue: :down}, or %{red: :up_down, blue: nil}"
  def remote_buttons(sensor, channel) when channel in 1 .. 4 do
		set_remote_mode(sensor)
		value = get_attribute(sensor, "value#{channel - 1}", :integer)
		case value do
			1 -> %{red: :up, blue: nil}
			2 -> %{red: :down, blue: nil}
			3 -> %{red: nil, blue: :up}
			4 -> %{red: nil, blue: :down}
			5 -> %{red: :up, blue: :up}
			6 -> %{red: :up, blue: :down}
			7 -> %{red: :down, blue: :up}
			8 -> %{red: :down, blue: :down}
			10 -> %{red: :up_down, blue: nil}
			11 -> %{red: nil, blue: :up_down}
      _ -> %{red: nil, blue: nil} # 0 or 9
    end
  end

	@doc "Are one or more remote button pushed on a given channel?"
  def remote_pushed?(sensor, channel) when channel in 1 .. 4 do
		%{red: red, blue: blue} = remote_buttons(sensor, channel)
		red != nil || blue != nil
  end

	@doc "Is the beacon turned on on a given channel in remote mode?"
  def remote_beacon_on?(sensor, channel) when channel in 1 .. 4 do
		set_remote_mode(sensor)
		get_attribute(sensor, "value#{channel - 1}", :integer) == 9
  end	

  ### PRIVATE

  defp set_proximity_mode(sensor) do
		if mode(sensor) != :proximity do
			LegoSensor.set_mode(sensor, @proximity)
	  end
	end

	defp set_seek_mode(sensor) do
		if mode(sensor) != :seek do
			LegoSensor.set_mode(sensor, @seek)
		end
	end

	defp set_remote_mode(sensor) do
		if mode(sensor) != :remote do
			LegoSensor.set_mode(sensor, @remote)
    end
	end		

	# Give currently set mode
  defp mode(sensor) do
		case LegoSensor.mode(sensor) do
			@proximity -> :proximity
			@seek -> :seek
			@remote -> :remote
    end
  end

end
