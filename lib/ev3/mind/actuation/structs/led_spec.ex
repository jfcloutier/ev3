defmodule Ev3.LEDSpec do
	@moduledoc "Struct for motor specifications"

	defstruct name: nil, position: nil, color: nil

	@doc "Does a motor match a motor spec?"
	def matches?(%Ev3.MotorSpec{} = motor_spec, device) do
		device.class == :motor and device.port == motor_spec.port
	end

	def matches?(%Ev3.LEDSpec{} = led_spec, device) do
		device.class == :led and device.props.position == led_spec.position and device.props.color == led_spec.color
	end

end
