defmodule Ev3.Actuator do
	@moduledoc "An actuator that translates intents into commands sent to motors"

	require Logger
	alias Ev3.LegoMotor
	alias Ev3.Script
	alias Ev3.MotorSpec
	alias Ev3.Device

		@doc "Start an actuator from a configuration"
	def start_link(actuator_config) do
		Logger.info("Starting #{__MODULE__} #{actuator_config.name}")
		Agent.start_link(fn() -> %{actuator_config: actuator_config,
															 motors: find_motors(actuator_config.motor_specs)
															} end,
										 [name: actuator_config.name])
	end

	def realize_intent(name, intent) do
		Agent.update(
			name,
			fn(state) ->
				state.actuator_config.activations
				|> Enum.filter_map(
					fn(activation) -> activation.intent == intent.about end,
					fn(activation) -> activation.action end)
				|> Enum.each(
					fn(action) ->
						script = action.(intent, state.motors)
						Script.execute(script)
					end)
				state
			end,
			30_000
		)
	end

	### Private

	defp find_motors(motor_spec) do
		all_motors = LegoMotor.motors()
		Enum.reduce(
			motor_spec,
			%{},
			fn(motor_spec, acc) ->
				%Device{} = motor = Enum.find(all_motors,
													&(MotorSpec.matches?(motor_spec, &1)))
				Map.put(acc, motor_spec.name, motor)
			end)
	end

end
