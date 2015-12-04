defmodule Ev3.Actuator do
	@moduledoc "An actuator that translates intents into commands sent to motors"

	require Logger
	alias Ev3.Intent

		@doc "Start an actuator from a configuration"
	def start_link(actuator_config) do
		Logger.info("Starting #{__MODULE__} #{actuator_config.name}")
		Agent.start_link(fn() -> %{actuator_config: actuator_config} end,
										 [name: actuator_config.name])
	end

	def realize_intent(name, intent) do
		Agent.update(
			name,
			fn(state) ->
				#todo
				state
			end
		)
	end

end
