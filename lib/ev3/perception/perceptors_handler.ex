defmodule Ev3.PerceptorsHandler do
	@docmodule "Perceptors handler"

	use GenEvent
	require Logger

	alias Ev3.Perceptor
	alias Ev3.EventManager
	alias Ev3.Perception

	### Callbacks

	def init(_) do
		Logger.info("Starting #{__MODULE__}")
		perceptor_defs = Perception.perceptor_defs()
		{:ok, %{perceptor_defs: perceptor_defs}}
	end

	def handle_event({:percept, percept}, state) do
		process_percept(percept, state)
		{:ok, state}
	end

	### Private

	defp process_percept(percept, %{perceptor_defs: perceptor_defs}) do
		Enum.map(perceptor_defs,
			fn(perceptor_def) ->
				case Perceptor.analyze_percept(perceptor_def.name, percept) do
					nil -> :ok
					new_percept ->
						EventManager.notify_percept(%{new_percept |
																					retain: perceptor_def.retain,
																					source: perceptor_def.name} )
				end
			end)
	end

end
