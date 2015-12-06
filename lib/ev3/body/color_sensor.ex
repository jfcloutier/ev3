defmodule Ev3.ColorSensor do
	@moduledoc "Color sensor"
	@behaviour Ev3.Sensing

  import Ev3.Sysfs
	alias Ev3.LegoSensor
	require Logger

  @reflect "COL-REFLECT"
	@ambient "COL-AMBIENT"
  @color "COL-COLOR"

	### Ev3.Sensing behaviour
	
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

	def sensitivity(_sensor, sense) do
		case sense do
			:color -> nil
			:ambient -> 2
			:reflected -> 2
		end
	end

	####

	@doc "Get the reflected light intensity as percentage"
	def reflected_light(sensor) do
		updated_sensor = set_reflect_mode(sensor)
		value = get_attribute(updated_sensor, "value0", :integer)
		{value, updated_sensor}
	end

	@doc "Get the color"
	def color(sensor) do
		updated_sensor = set_color_mode(sensor)
		value = case get_attribute(updated_sensor, "value0", :integer) do
							0 -> nil
							1 -> :black
							2 -> :blue
							3 -> :green
							4 -> :yellow
							5 -> :red
							6 -> :white
							7 -> :brown
							color ->
								Logger.warn("Unknown color #{color}")
								:mystery
						end
		{value, updated_sensor}
	end

	@doc "Get the ambient light intensity as percentage"
	def ambient_light(sensor) do
		updated_sensor = set_ambient_mode(sensor) 
		value = get_attribute(updated_sensor, "value0", :integer)
		{value, updated_sensor}
	end

 ### PRIVATE

 	defp set_reflect_mode(sensor) do
		LegoSensor.set_mode(sensor, @reflect)
	end

	defp set_ambient_mode(sensor) do
		LegoSensor.set_mode(sensor, @ambient)
	end

	defp set_color_mode(sensor) do
		LegoSensor.set_mode(sensor, @color)
	end

end
