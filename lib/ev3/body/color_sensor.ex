defmodule Ev3.ColorSensor do
	@moduledoc "Color sensor"

  import Ev3.Sysfs
	alias Ev3.LegoSensor

  @reflect "COL-REFLECT"
	@ambient "COL-AMBIENT"
  @color "COL-COLOR"

	@doc "Get the reflected light intensity as percentage"
	def reflected_light(sensor) do
		set_reflect_mode(sensor)
		get_attribute(sensor, "value0", :integer)
	end

	@doc "Get the color"
	def color(sensor) do
		set_color_mode(sensor)
		case get_attribute(sensor, "value0", :integer) do
			0 -> nil
			1 -> :black
			2 -> :blue
			3 -> :green
			4 -> :yellow
			5 -> :red
			6 -> :white
			7 -> :brown
		end
	end

	@doc "Get the ambient light intensity as percentage"
	def ambient_light(sensor) do
		set_ambient_mode(sensor)
		get_attribute(sensor, "value0", :integer)
	end

 ### PRIVATE

 	defp set_reflect_mode(sensor) do
		if mode(sensor) != :reflect do
			LegoSensor.set_mode(sensor, @reflect)
    end
	end

	defp set_ambient_mode(sensor) do
		if mode(sensor) != :ambient do
			LegoSensor.set_mode(sensor, @ambient)
    end
	end

	defp set_color_mode(sensor) do
		if mode(sensor) != :color do
			LegoSensor.set_mode(sensor, @color)
    end
	end

	# Give currently set mode
  defp mode(sensor) do
		case LegoSensor.mode(sensor) do
			@reflect -> :reflect
			@ambient -> :ambient
			@color -> :color
    end
  end

end
