defmodule Ev3.Perceptor do
	@docmodule "An analyzer and producer of percepts"

	alias Ev3.Memory
	require Logger

	@doc "Start a perceptor from a configuration"
	def start_link(perceptor_config) do
		Logger.info("Starting #{__MODULE__} #{perceptor_config.name}")
		Agent.start_link(fn() -> %{perceptor_config: perceptor_config} end,
										 [name: perceptor_config.name])
	end

	@doc "A perceptor analyzes a percept and returns either nil or a new percept"
	def analyze_percept(name, percept) do
		Logger.debug("#{name} analyzing #{inspect percept}")
		Agent.get_and_update(
			name,
			fn(state) ->
				config = state.perceptor_config
				analysis = if percept.sense in config.senses do
										 window = Memory.recall(config.senses, config.span)
									#	 Logger.debug("Testing #{config.name} with #{inspect percept} vs #{inspect window}")
										 config.logic.(percept, window)  # a percept or nil
									 else
										 nil
									 end
				{analysis, state}
			end)
	end
	
end
