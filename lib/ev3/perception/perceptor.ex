defmodule Ev3.Perceptor do
	@docmodule "An analyzer and producer of percepts"

	alias Ev3.PerceptorDef
	require Logger

	def start_link(perceptor_def) do
		Logger.info("Starting perceptor #{perceptor_def.name}")
		Agent.start_link(fn() -> %{perceptor_def: perceptor_def} end, [name: perceptor_def.name])
	end

	def analyze_percept(name, percept) do
		Agent.get_and_update(
			name,
			fn(state) ->
				analysis = interpret(percept, state.perceptor_def) # a percept or nil
				{analysis, state}
			end)
	end

	### Private

	defp interpret(percept, %PerceptorDef{senses: senses, span: span, logic: logic}) do
		window = Memory.recall(senses, span)		
		logic.(percept, window) # returns nil or a percept with sense and value set
	end
	
end
