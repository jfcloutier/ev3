defmodule Ev3.Motivator do
	@moduledoc "An analyzer of percepts and producer of motives"

	require Logger
	alias Ev3.Memory

	@doc "Start a motivator from a configuration"
	def start_link(motivator_config) do
		Logger.info("Starting #{__MODULE__} #{motivator_config.name}")
		Agent.start_link(fn() -> %{motivator_config: motivator_config} end,
										 [name: motivator_config.name])
	end

	@doc "A motivator reacts to a percept by returning either nil or a new motive"
	def react_to_percept(name, percept) do
		Agent.get_and_update(
			name,
			fn(state) ->
				config = state.motivator_config
				reaction = if percept.about in config.focus.senses do
										 memories = Memory.since(config.span, senses: config.focus.senses, motives: config.focus.motives, intents: config.focus.intents)
										 config.logic.(percept, memories)  # returns a motive or nil
									 else
										 nil
									 end
				{reaction, state}
			end)
	end
	
end
