defmodule Ev3.ActuatorConfig do
	@moduledoc "An actuator's configuration"

	defstruct name: nil, intent: nil, motor_specs: nil, logic: nil

	@doc "Make a new actuator"
	def new(name: name, intent: intent_name, motor_specs: motor_specs, logic: logic) do
		%Ev3.ActuatorConfig{name: name,
												intent: intent_name,
												motor_specs: motor_specs,
												logic: logic}
	end

end
