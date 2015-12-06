defmodule Ev3.MotorSpec do
	@moduledoc "Struct for motor specifications"

	defstruct name: nil, port: nil

	@doc "Does a motor match a motor spec?"
	def matches?(motor_spec, device) do
		device.class == :motor and device.port == motor_spec.port
	end
	
end
