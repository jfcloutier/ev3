defmodule Ev3.Mock.ColorSensor do
	@moduledoc "A mock color sensor"

	@behaviour Ev3.Sensing

	def new() do
		 %Ev3.Device{class: :sensor,
						path: "/mock/color_sensor", 
						type: :color}
	end

	# Sensing

	def senses(_) do
		[:color, :ambient, :reflected]
	end

	def read(sensor, sense) do
		case sense do
			:color -> color(sensor)
			:ambient -> ambient_light(sensor)
			:reflected -> reflected_light(sensor)
		end
	end

	def pause(_) do
		500
	end

	def sensitivity(sensor) do
		nil
	end

	### Private

	def color(sensor) do
		value = case :random.uniform(8) - 1 do
							0 -> nil
							1 -> :black
							2 -> :blue
							3 -> :green
							4 -> :yellow
							5 -> :red
							6 -> :white
							7 -> :brown
						end
		{value, sensor}
	end

	def ambient_light(sensor) do
		value = :random.uniform(101) - 1
		{value, sensor}
	end

		def reflected_light(sensor) do
		value = :random.uniform(101) - 1
		{value, sensor}
	end

end
