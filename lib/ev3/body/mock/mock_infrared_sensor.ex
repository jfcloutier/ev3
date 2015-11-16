defmodule Ev3.Mock.InfraredSensor do
	@moduledoc "A mock infrared sensor"

	@behaviour Ev3.Sensing
  @max_beacon_channels 4

	def new() do
		%Ev3.Device{class: :sensor,
						path: "/mock/infrared_sensor", 
						type: :infrared}
	end

	### Sensing
	
	def senses(_) do
		beacon_senses = Enum.map(1.. @max_beacon_channels, 
							 &([{:beacon_heading, &1}, {:beacon_distance, &1}, {:beacon_on, &1}]))
		|> List.flatten()
		[:proximity | beacon_senses]
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
		nil
	end

	### Private

	defp proximity(sensor) do
		value = :random.uniform(20)
		{value, sensor}
	end

	defp seek_heading(sensor, _channel) do
		value = 25 - :random.uniform(50)
    {value, sensor}
	end

	defp seek_distance(sensor, _channel) do
		value =
			if :random.uniform(2) == 2 do
				:random.uniform(101) - 1
			else
				-128
			end
    {value, sensor}
	end

	defp seek_beacon_on?(sensor, _channel) do
		value = :random.uniform(2) == 2
		{value, sensor}
	end
	
end
