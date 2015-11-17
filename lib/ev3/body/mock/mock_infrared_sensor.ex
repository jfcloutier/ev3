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
							 &([{:beacon_heading, &1}, {:beacon_distance, &1}, {:beacon_on, &1}, {:remote_buttons, &1}]))
		|> List.flatten()
		[:proximity | beacon_senses]
	end

	def read(sensor, :proximity) do
		proximity(sensor)			
	end

	def read(sensor, {:remote_buttons, channel}) do
		remote_buttons(sensor, channel)
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

	def sensitivity(_sensor, _sense) do
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

	defp remote_buttons(sensor, _channel) do
		value = case :random.uniform(12) - 1 do
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
		{value, sensor}
	end
	
end
