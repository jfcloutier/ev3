defmodule Ev3.Mock.ColorSensor do
	@moduledoc "A mock color sensor"

	@behaviour Ev3.Sensing

	def new() do
		 %Ev3.Device{class: :sensor,
						path: "/mock/color_sensor", 
						type: :color,
            mock: true  }
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

	def nudge(_sensor, sense, value, previous_value) do
		case sense do
			:color -> nudge_color(value, previous_value)
			:ambient -> nudge_ambient_light(value, previous_value)
			:reflected -> nudge_reflected_light(value, previous_value)
		end
	end

	def pause(_) do
		500
	end

	def sensitivity(_sensor, _sense) do
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

  def nudge_color(value, previous_value) do
    if previous_value == nil or :random.uniform(4) == 1 do
      value
    else
      previous_value
    end 
  end

  
	def ambient_light(sensor) do
		value = :random.uniform(5)
		{value, sensor}
	end

  def nudge_ambient_light(_value, nil) do
    :random.uniform(101) - 1
  end

  def nudge_ambient_light(value, previous_value) do
    IO.puts("Value = #{value}, Previous = #{previous_value}")
    (previous_value + value) |> max(0) |> min(100)
  end
  
	def reflected_light(sensor) do
		value = :random.uniform(5)
		{value, sensor}
	end

  def nudge_reflected_light(_value, nil) do
    :random.uniform(101) - 1
  end

  def nudge_reflected_light(value, previous_value) do
    previous_value + value |> max(0) |> min(100)
  end

end
