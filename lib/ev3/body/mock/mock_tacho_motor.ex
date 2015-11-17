defmodule Ev3.Mock.Tachomotor do
	@moduledoc "A mock large tachomotor"

	@behaviour Ev3.Sensing

	def new(type) do
			 %Ev3.Device{class: :motor,
						path: "/mock/#{type}_tachomotor", 
						type: type}
  end

 # Sensing

	def senses(_) do
		[:speed, :position, :duty_cycle, :run_status]
	end

	def read(motor, sense) do
		case sense do
			:speed -> current_speed(motor)
			:position -> current_position(motor)
			:duty_cycle -> current_duty_cycle(motor)
			:run_status -> current_run_status(motor)
		end
	end

	def pause(_) do
		500
	end

	def sensitivity(_motor, _sense) do
		nil
	end

	### PRIVATE

	defp current_speed(motor) do
		value = :random.uniform() * :random.uniform(10)
		{value, motor}
	end

	defp current_position(motor) do
		value = :random.uniform(200) - 100
		{value, motor}
	end

	defp current_duty_cycle(motor) do
		value = :random.uniform(100)
		{value, motor}
	end

	defp current_run_status(motor) do
		value = case :random.uniform(3) do
							0 -> :running
							1 -> :stopped
							2 -> :stalled
							3 -> :holding
						end
		{value, motor}
	end
	
end
