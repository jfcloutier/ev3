defmodule Ev3.InfraredSensor do
	@moduledoc "Infrared sensor"
	@behaviour Ev3.Sensing

	import Ev3.Sysfs
	alias Ev3.LegoSensor

	@proximity "IR-PROX"
	@seek "IR-SEEK"
  @remote "IR-REMOTE"
  @max_beacon_channels 4
	
	### Ev3.Sensing behaviour
	
	def senses(_) do
		# beacon_senses = Enum.map(1.. @max_beacon_channels, 
		# 					 &([{:beacon_heading, &1}, {:beacon_distance, &1}, {:beacon_on, &1}]))
		# |> List.flatten()
		# [:proximity | beacon_senses]
		[:proximity]
	end

	def read(sensor, :proximity) do
		proximity(sensor)			
	end

	def read(sensor, {beacon_sense, channel}) do
		case beacon_sense do
			:beacon_heading -> seek_heading(sensor, channel)
			:beacon_distance -> seek_distance(sensor, channel)
			:beacon_on -> seek_beacon_on?(sensor, channel)
		end
	end

	def pause(_) do
	 500
	end

	def sensitivity(sensor) do
		case mode(sensor) do
			:proximity -> 2
			:seek -> 2
			:remote -> nil
		end
	end

  ####
	
@doc "Get proximity as a percent - 70+cm ~> 100, 0cm ~> 1"
  def proximity(sensor) do
		updated_sensor = set_proximity_mode(sensor)
		value = get_attribute(updated_sensor, "value0", :integer)
		{value, updated_sensor}
  end

	@doc "Get beacon heading on a channel (-25 for far left, 25 for far right, 0 if absent or straight ahead)"
  def seek_heading(sensor, channel) when channel in 1 .. @max_beacon_channels do 
	updated_sensor = set_seek_mode(sensor)
	value = get_attribute(updated_sensor, "value#{(channel - 1) * 2}", :integer)
	{value, updated_sensor}
  end

	@doc "Get beacon distance on a channel 
  (as percentage, or -128 if absent)"
  def seek_distance(sensor, channel) when channel in 1 .. @max_beacon_channels do
		updated_sensor = set_seek_mode(sensor)
		value = get_attribute(updated_sensor, "value#{((channel - 1) * 2) + 1}", :integer)
		{value, updated_sensor}
  end

  @doc "Is the beacon on in seek mode?"
	def seek_beacon_on?(sensor, channel) when channel in 1 .. @max_beacon_channels do
		{distance, sensor1} = seek_distance(sensor, channel)
		{heading, sensor2} =  seek_heading(sensor1, channel)
		{distance == -128 && heading == 0, sensor2}
  end

	@doc "Get remote button pushed (maximum two buttons) on a channel. 
  (E.g. %{red: :up, blue: :down}, or %{red: :up_down, blue: nil}"
  def remote_buttons(sensor, channel) when channel in 1 .. @max_beacon_channels do
		updated_sensor = set_remote_mode(sensor)
		val = get_attribute(updated_sensor, "value#{channel - 1}", :integer)
		value = case val do
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
		{value, updated_sensor}
  end

	@doc "Are one or more remote button pushed on a given channel?"
  def remote_pushed?(sensor, channel) when channel in 1 .. @max_beacon_channels do
		{%{red: red, blue: blue}, updated_sensor} = remote_buttons(sensor, channel)
		{red != nil || blue != nil, updated_sensor}
  end

	@doc "Is the beacon turned on on a given channel in remote mode?"
  def remote_beacon_on?(sensor, channel) when channel in 1 .. @max_beacon_channels do
		updated_sensor = set_remote_mode(sensor)
		value = get_attribute(updated_sensor, "value#{channel - 1}", :integer) == 9
		{value, updated_sensor}
  end

	  ### PRIVATE

  defp set_proximity_mode(sensor) do
		LegoSensor.set_mode(sensor, @proximity)
	end

	defp set_seek_mode(sensor) do
		LegoSensor.set_mode(sensor, @seek)
	end

	defp set_remote_mode(sensor) do
		LegoSensor.set_mode(sensor, @remote)
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
