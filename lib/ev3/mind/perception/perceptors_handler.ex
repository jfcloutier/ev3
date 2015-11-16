defmodule Ev3.PerceptorsHandler do
	@moduledoc "Perceptors handler"

	use GenEvent
	require Logger

	alias Ev3.Perceptor
	alias Ev3.CNS
	alias Ev3.Perception

	### Callbacks

	def init(_) do
		Logger.info("Starting #{__MODULE__}")
		perceptor_configs = Perception.perceptor_configs()
		{:ok, %{perceptor_configs: perceptor_configs}}
	end

	def handle_event({:perceived, percept}, state) do
		process_percept(percept, state)
		{:ok, state}
	end

	def handle_event(_event, state) do
#		Logger.debug("#{__MODULE__} ignored #{inspect event}")
		{:ok, state}
	end

	### Private

	defp process_percept(percept, %{perceptor_configs: perceptor_configs}) do
		perceptor_configs
		|> Enum.filter(&(percept.sense in &1.senses))
		|> Enum.each(
			fn(perceptor_config) ->
				case Perceptor.analyze_percept(perceptor_config.name, percept) do
					nil -> :ok
					new_percept ->
						CNS.notify_perceived(%{new_percept |
																						retain: perceptor_config.retain,
																						source: perceptor_config.name} )
				end
			end)
	end

end
