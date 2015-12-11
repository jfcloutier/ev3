defmodule Ev3.ActuatorConfig do
	@moduledoc "An actuator's configuration"

	defstruct name: nil, type: nil, specs: nil, activations: nil, intents: nil

	@doc "Make a new actuator"
	def new(name: name, type: type, specs: specs, activations: activations) do
		config = %Ev3.ActuatorConfig{name: name,
																 type: type,
																 specs: specs,
																 activations: activations}
		%Ev3.ActuatorConfig{config | intents: intent_names(config.activations)}
	end

	defp intent_names(activations) do
		set = Enum.reduce(
			activations,
			HashSet.new(),
			fn(activation, acc) -> HashSet.put(acc, activation.intent) end
		)
		Enum.to_list(set)
	end

end
