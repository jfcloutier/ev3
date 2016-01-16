defmodule Ev3.LEDSpec do
	@moduledoc "Struct for motor specifications"
  
  # properties name and props are required to be a *Spec
	defstruct name: nil, position: nil, color: nil, props: %{}

	@doc "Does an LED match an LED spec?"
	def matches?(%Ev3.LEDSpec{} = led_spec, device) do
		device.class == :led and device.props.position == led_spec.position and device.props.color == led_spec.color
	end

end
