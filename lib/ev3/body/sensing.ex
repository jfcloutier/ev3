defprotocol Ev3.Sensing do

	@doc "Get all the senses a sensor possesses"
	def senses(sensor)

	@doc "Get the current value of a sense"
	def read(sensor, sense)

	def pause(sensor)

end

defimpl Ev3.Sensing, for: Ev3.TouchSensor do

	def senses(_) do
		[:touch]
	end

	def read(sensor, :touch) do
		Ev3.InfraredSensor.state(sensor)
	end

	def pause(_) do
		100
	end
	
end

defimpl Ev3.Sensing, for: Ev3.ColorSensor do

	def senses(_) do
		[:color, :ambient, :reflected]
	end

	def read(sensor, sense) do
		case sense do
			:color -> Ev3.ColorSensor.color(sensor)
			:ambient -> Ev3.ColorSensor.ambient_light(sensor)
			:reflected -> Ev3.ColorSensor.reflected_light(sensor)
		end
	end

	def pause(_) do
		500
	end
	
end

defimpl Ev3.Sensing, for: Ev3.InfraredSensor do

	def senses(_) do
		beacon_senses = Enum.map(1..4,
							 &([{:beacon_heading, &1}, {:beacon_distance, &1}, {:beacon_on, &1}]))
		|> List.flatten()
		[:proximity | beacon_senses]
	end

	def read(sensor, :proximity) do
		Ev3.InfraredSensor.proximity(sensor)			
	end

	def read(sensor, {beacon_sense, channel}) do
		case beacon_sense do
			:beacon_heading -> Ev3.InfraredSensor.seek_heading(sensor, channel)
			:beacon_distance -> Ev3.InfraredSensor.seek_distance(sensor, channel)
			:beacon_on -> Ev3.InfraredSensor.seek_beacon_on?(sensor, channel)
		end
	end

	def pause(_) do
	 100
	end

end
